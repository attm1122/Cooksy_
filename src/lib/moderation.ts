/**
 * Content Moderation System
 * 
 * Protects against inappropriate content in recipe imports and user-generated content.
 * Runs on both client (quick checks) and server (comprehensive checks).
 */

import { captureError, captureMessage } from "./monitoring";
import { supabase } from "./supabase";

// Blocked creators/domains - URLs containing these are rejected
const BLOCKED_CREATORS: string[] = [
  // Add specific creators or domains that violate content policies
  // e.g., "inappropriate-creator-name",
];

// Blocked keywords in titles/descriptions (case-insensitive)
const BLOCKED_KEYWORDS = [
  // Hate speech
  "hate", "racist", "nazi", "supremacist",
  // Violence
  "kill", "murder", "violence", "attack",
  // Adult content
  "porn", "xxx", "sex", "nude", "naked",
  // Drugs
  "cocaine", "heroin", "meth", "fentanyl",
  // Weapons
  "bomb", "weapon", "gun", "shoot",
];

// Suspicious patterns (regex)
const SUSPICIOUS_PATTERNS = [
  /\b(buy|sell|order)\s+(drugs|pills|meds)\b/i,
  /\b(click\s+here|visit\s+site)\s+for\s+(adult|xxx)\b/i,
  /\b(free\s+money|get\s+rich|make\s+\$\d+)/i,
];

// Minimum confidence threshold for recipe extraction
const MIN_CONFIDENCE_SCORE = 20;

// Maximum content length (prevents abuse)
const MAX_TITLE_LENGTH = 200;
const MAX_DESCRIPTION_LENGTH = 2000;
const MAX_INGREDIENT_NAME_LENGTH = 100;

export type ModerationResult = {
  allowed: boolean;
  reason?: string;
  severity: "none" | "low" | "medium" | "high";
  flaggedKeywords?: string[];
  action: "allow" | "flag" | "block";
};

export type ContentToModerate = {
  url: string;
  title?: string;
  description?: string;
  creator?: string;
  ingredients?: { name: string }[];
  confidenceScore?: number;
};

/**
 * Quick URL-based moderation (runs on client)
 */
export const moderateUrl = (url: string): ModerationResult => {
  const lowerUrl = url.toLowerCase();
  
  // Check blocked creators/domains
  for (const blocked of BLOCKED_CREATORS) {
    if (lowerUrl.includes(blocked.toLowerCase())) {
      return {
        allowed: false,
        reason: "Source not allowed",
        severity: "high",
        action: "block"
      };
    }
  }
  
  // Check for URL shorteners (often used to hide malicious links)
  const suspiciousDomains = ["bit.ly", "t.co", "tinyurl", "goo.gl", "ow.ly"];
  for (const domain of suspiciousDomains) {
    if (lowerUrl.includes(domain)) {
      return {
        allowed: false,
        reason: "URL shorteners not allowed for security",
        severity: "medium",
        action: "block"
      };
    }
  }
  
  return { allowed: true, severity: "none", action: "allow" };
};

/**
 * Content-based moderation (runs on extracted content)
 */
export const moderateContent = (content: ContentToModerate): ModerationResult => {
  const flaggedKeywords: string[] = [];
  
  // Check confidence score
  if (content.confidenceScore !== undefined && content.confidenceScore < MIN_CONFIDENCE_SCORE) {
    return {
      allowed: false,
      reason: `Content confidence too low (${content.confidenceScore})`,
      severity: "medium",
      action: "block"
    };
  }
  
  // Check length limits
  if (content.title && content.title.length > MAX_TITLE_LENGTH) {
    return {
      allowed: false,
      reason: "Title exceeds maximum length",
      severity: "low",
      action: "block"
    };
  }
  
  if (content.description && content.description.length > MAX_DESCRIPTION_LENGTH) {
    return {
      allowed: false,
      reason: "Description exceeds maximum length",
      severity: "low",
      action: "block"
    };
  }
  
  // Combine all text for keyword checking
  const textToCheck = [
    content.title,
    content.description,
    content.creator
  ].filter(Boolean).join(" ").toLowerCase();
  
  // Check blocked keywords
  for (const keyword of BLOCKED_KEYWORDS) {
    if (textToCheck.includes(keyword.toLowerCase())) {
      flaggedKeywords.push(keyword);
    }
  }
  
  // Check suspicious patterns
  for (const pattern of SUSPICIOUS_PATTERNS) {
    if (pattern.test(textToCheck)) {
      return {
        allowed: false,
        reason: "Content matches suspicious patterns",
        severity: "high",
        flaggedKeywords: [...flaggedKeywords, "suspicious_pattern"],
        action: "block"
      };
    }
  }
  
  // Check ingredients
  if (content.ingredients) {
    for (const ingredient of content.ingredients) {
      if (ingredient.name.length > MAX_INGREDIENT_NAME_LENGTH) {
        return {
          allowed: false,
          reason: "Ingredient name exceeds maximum length",
          severity: "low",
          action: "block"
        };
      }
    }
  }
  
  // Determine action based on flagged content
  if (flaggedKeywords.length > 0) {
    const highSeverityKeywords = ["porn", "xxx", "sex", "nude", "kill", "murder", "bomb"];
    const hasHighSeverity = flaggedKeywords.some(k => 
      highSeverityKeywords.some(h => k.includes(h))
    );
    
    if (hasHighSeverity) {
      captureMessage("High severity content blocked", {
        url: content.url,
        keywords: flaggedKeywords.join(","),
        creator: content.creator
      });
      
      return {
        allowed: false,
        reason: "Content violates community guidelines",
        severity: "high",
        flaggedKeywords,
        action: "block"
      };
    }
    
    // Medium severity - flag for review but allow
    return {
      allowed: true,
      reason: "Content flagged for review",
      severity: "medium",
      flaggedKeywords,
      action: "flag"
    };
  }
  
  return { allowed: true, severity: "none", action: "allow" };
};

/**
 * Report content for moderation review
 */
export const reportContent = async (params: {
  recipeId: string;
  reason: string;
  details?: string;
  reporterUserId?: string;
}): Promise<{ success: boolean; error?: string }> => {
  try {
    if (!supabase) {
      return { success: false, error: "Supabase not configured" };
    }

    // Call the database function to create report
    const { data, error } = await supabase.rpc("report_recipe_content", {
      p_recipe_id: params.recipeId,
      p_reason: params.reason,
      p_details: params.details || null,
      p_reporter_user_id: params.reporterUserId || null
    });

    if (error) {
      throw error;
    }

    if (data && !data.success) {
      return { success: false, error: data.error };
    }
    
    // Also log to monitoring
    captureMessage("Content reported", {
      recipeId: params.recipeId,
      reason: params.reason,
      reporterId: params.reporterUserId || "anonymous",
      reportId: data?.report_id
    });
    
    return { success: true, error: undefined };
  } catch (error) {
    captureError(error, { action: "report_content", recipeId: params.recipeId });
    return { 
      success: false, 
      error: error instanceof Error ? error.message : "Failed to submit report" 
    };
  }
};

/**
 * Check if user is rate limited for content creation
 */
export const checkContentRateLimit = (userId: string): { 
  allowed: boolean; 
  retryAfterMs?: number;
  remaining?: number;
} => {
  // In production, check against Supabase/redis
  // For now, always allow (backend has proper rate limiting)
  return { allowed: true, remaining: 100 };
};

/**
 * Get moderation status for admin dashboard
 */
export const getModerationStats = async (): Promise<{
  pendingReports: number;
  flaggedContent: number;
  blockedToday: number;
}> => {
  try {
    if (!supabase) {
      return { pendingReports: 0, flaggedContent: 0, blockedToday: 0 };
    }

    const { data, error } = await supabase.rpc("get_moderation_stats");
    
    if (error || !data || data.length === 0) {
      return {
        pendingReports: 0,
        flaggedContent: 0,
        blockedToday: 0
      };
    }
    
    return {
      pendingReports: data[0].pending_reports,
      flaggedContent: data[0].flagged_content,
      blockedToday: data[0].blocked_today
    };
  } catch {
    return {
      pendingReports: 0,
      flaggedContent: 0,
      blockedToday: 0
    };
  }
};
