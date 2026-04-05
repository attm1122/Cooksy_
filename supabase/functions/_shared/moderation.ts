/**
 * Server-side content moderation
 * Mirrors client-side moderation for defense in depth
 */

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

// Blocked creators/domains
const BLOCKED_CREATORS: string[] = [
  // Add specific creators here
];

export type ModerationResult = {
  allowed: boolean;
  reason?: string;
  severity: "none" | "low" | "medium" | "high";
  action: "allow" | "flag" | "block";
};

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
  
  // Check for URL shorteners
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

export const moderateContent = (content: {
  title?: string;
  description?: string;
  creator?: string;
}): ModerationResult => {
  const textToCheck = [
    content.title,
    content.description,
    content.creator
  ].filter(Boolean).join(" ").toLowerCase();
  
  // Check blocked keywords
  for (const keyword of BLOCKED_KEYWORDS) {
    if (textToCheck.includes(keyword.toLowerCase())) {
      return {
        allowed: false,
        reason: "Content violates community guidelines",
        severity: "high",
        action: "block"
      };
    }
  }
  
  // Check suspicious patterns
  for (const pattern of SUSPICIOUS_PATTERNS) {
    if (pattern.test(textToCheck)) {
      return {
        allowed: false,
        reason: "Content matches suspicious patterns",
        severity: "high",
        action: "block"
      };
    }
  }
  
  return { allowed: true, severity: "none", action: "allow" };
};
