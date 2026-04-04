# Cooksy Video Content Extraction Layer

This document describes the production-ready video content extraction layer for Cooksy, which extracts recipe information from YouTube, TikTok, and Instagram sources.

## Overview

The extraction layer transforms cooking video URLs into structured recipe data by:

1. **Platform Detection**: Identifying the source platform from the URL
2. **Content Extraction**: Fetching video metadata, transcripts, captions, and thumbnails
3. **Signal Processing**: Converting raw content into recipe-relevant signals
4. **Recipe Reconstruction**: Building structured recipes from extracted signals

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   User Input    │────▶│  Extraction      │────▶│  Recipe         │
│   (Video URL)   │     │  Orchestrator    │     │  Reconstruction │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
   │   YouTube   │     │   TikTok    │     │  Instagram  │
   │   Adapter   │     │   Adapter   │     │   Adapter   │
   └─────────────┘     └─────────────┘     └─────────────┘
```

## Platform Support

### YouTube (Fully Supported)

**Extraction Sources:**
- oEmbed API (title, author, thumbnail)
- Watch page scraping (description, metadata)
- Caption/transcript extraction (timed text tracks)

**Features:**
- Full transcript extraction with timestamps
- Multiple thumbnail quality options
- Structured caption segments
- ~95% success rate for public videos

**Rate Limits:** 30 requests/minute

### TikTok (Partially Supported)

**Extraction Sources:**
- SSR hydration data scraping
- Open Graph metadata
- RapidAPI fallback (optional)

**Features:**
- Video metadata (title, creator, description)
- Caption parsing for recipe hints
- Thumbnail extraction
- ~60% success rate with scraping
- ~85% success rate with RapidAPI

**Rate Limits:** 10 requests/minute

**Configuration:**
```bash
# Enable web scraping (may be blocked)
EXPO_PUBLIC_ENABLE_TIKTOK_SCRAPING=true

# Use RapidAPI for better reliability
EXPO_PUBLIC_RAPIDAPI_KEY=your_key
EXPO_PUBLIC_RAPIDAPI_HOST=tiktok-api.p.rapidapi.com
```

### Instagram (Limited Support)

**Extraction Sources:**
- Open Graph metadata
- JSON-LD structured data
- Basic page scraping

**Features:**
- Post/reel metadata
- Caption text extraction
- Recipe hint parsing
- Thumbnail extraction
- ~40% success rate (Instagram blocks scraping)

**Rate Limits:** 10 requests/minute

**Note:** Instagram actively blocks automated access. For production use, consider:
- Using Instagram Basic Display API
- Third-party scraping services
- Manual recipe entry fallback

## Configuration

### Environment Variables

```bash
# Extraction mode
EXPO_PUBLIC_RECIPE_IMPORT_MODE=auto  # mock | remote | auto

# Core extraction config
EXPO_PUBLIC_EXTRACTION_TIMEOUT_MS=30000

# RapidAPI (for TikTok)
EXPO_PUBLIC_RAPIDAPI_KEY=your_key
EXPO_PUBLIC_RAPIDAPI_HOST=tiktok-api.p.rapidapi.com

# OpenAI (for Whisper transcription)
EXPO_PUBLIC_OPENAI_API_KEY=your_key

# Scraping toggles
EXPO_PUBLIC_ENABLE_TIKTOK_SCRAPING=true
EXPO_PUBLIC_ENABLE_INSTAGRAM_SCRAPING=true
EXPO_PUBLIC_ENABLE_WHISPER_TRANSCRIPTION=true
```

## Features

### 1. Smart Caching

Extraction results are cached in memory with a 1-hour TTL:

```typescript
import { extractionCache, clearExtractionCache } from "@/features/recipes/extraction";

// Check cache status
console.log(extractionCache.size());

// Clear cache
clearExtractionCache();
```

### 2. Rate Limiting

Platform-specific rate limits prevent overwhelming source platforms:

```typescript
import { rateLimiter } from "@/features/recipes/extraction";

// Check if request can proceed
if (rateLimiter.canProceed("youtube")) {
  // Make extraction request
}

// Get wait time
const waitMs = rateLimiter.getWaitTimeMs("tiktok");

// Get status
const status = rateLimiter.getStatus("instagram");
// { remaining: 8, resetInMs: 45000 }
```

### 3. Extraction Analytics

Track extraction performance and health:

```typescript
import { extractionAnalytics, getExtractionStatus } from "@/features/recipes/extraction";

// Get metrics
const metrics = extractionAnalytics.getMetrics();
console.log({
  totalAttempts: metrics.totalAttempts,
  successRate: extractionAnalytics.getSuccessRate(),
  byPlatform: metrics.byPlatform
});

// Get health status
const health = extractionAnalytics.getHealthStatus();
console.log({
  healthy: health.healthy,
  issues: health.issues,
  recommendations: health.recommendations
});

// Get full status
const status = getExtractionStatus();
console.log(status.analytics);
console.log(status.health);
```

### 4. Background Job Processing

Queue and process extractions asynchronously:

```typescript
import { queueExtraction, waitForJobCompletion } from "@/features/recipes/extraction";

// Queue extraction
const job = queueExtraction(url, "youtube", 5);

// Subscribe to updates
const unsubscribe = backgroundJobProcessor.subscribe(job.id, (updatedJob) => {
  console.log(`Progress: ${updatedJob.progress}%`);
  console.log(`Status: ${updatedJob.status}`);
});

// Wait for completion
const completed = await waitForJobCompletion(job.id, 60000);
if (completed.status === "completed") {
  console.log("Extraction successful!");
}
```

### 5. Whisper Audio Transcription

For videos without captions, use OpenAI Whisper:

```typescript
import { transcribeYouTubeVideo, isWhisperAvailable } from "@/features/recipes/extraction";

if (isWhisperAvailable()) {
  const result = await transcribeYouTubeVideo(videoId, {
    language: "en",
    recipeHint: true  // Optimize for recipe content
  });
  
  if (result.success) {
    console.log(result.transcript);
    console.log(result.segments);
  }
}
```

**Note:** Whisper transcription requires server-side processing due to audio extraction limitations on mobile.

## Usage

### Basic Extraction

```typescript
import { extractRecipeContextFromUrl } from "@/features/recipes/services/extractionService";

const context = await extractRecipeContextFromUrl("https://youtube.com/watch?v=...");
// Returns RawRecipeContext with transcript, metadata, etc.
```

### Batch Extraction

```typescript
import { extractMultipleContexts } from "@/features/recipes/extraction";

const urls = [url1, url2, url3];
const results = await extractMultipleContexts(urls);

for (const [url, result] of results) {
  if (result.success) {
    console.log(`${url}: ${result.context.title}`);
  }
}
```

### With Options

```typescript
import { extractContextFromUrl } from "@/features/recipes/extraction";

const result = await extractContextFromUrl(url, {
  useCache: true,        // Use extraction cache
  timeoutMs: 30000,      // 30 second timeout
  retryCount: 2,         // Retry failed requests twice
  forceFresh: false      // Force fresh extraction (ignore cache)
});
```

## Error Handling

Extraction failures return structured errors:

```typescript
const result = await extractContextFromUrl(url);

if (!result.success) {
  switch (result.error.type) {
    case "unsupported_url":
      console.log("URL not supported");
      break;
    case "rate_limited":
      console.log(`Try again in ${result.error.retryAfter}ms`);
      break;
    case "content_unavailable":
      console.log("Video is private or deleted");
      break;
    case "timeout":
      console.log("Extraction timed out");
      break;
    default:
      console.log("Extraction failed:", result.error.message);
  }
  
  // Use fallback context
  if (result.fallbackContext) {
    // Proceed with partial data
  }
}
```

## Monitoring

Track extraction performance:

```typescript
import { getExtractionStatus } from "@/features/recipes/extraction";

const status = getExtractionStatus();
console.log({
  cacheSize: status.cacheSize,
  rateLimits: status.rateLimits,
  adapters: status.adapters,
  analytics: status.analytics,
  health: status.health
});
```

## Production Checklist

- [ ] Set `EXPO_PUBLIC_RECIPE_IMPORT_MODE=remote`
- [ ] Configure RapidAPI key for TikTok extraction
- [ ] Set up OpenAI API key for Whisper (optional)
- [ ] Enable scraping toggles based on your risk tolerance
- [ ] Set up monitoring for extraction success rates
- [ ] Configure fallback strategies for failed extractions
- [ ] Test with a variety of video URLs from each platform
- [ ] Implement user-facing error messages for extraction failures
- [ ] Set up extraction health monitoring dashboard

## Troubleshooting

### YouTube Transcript Not Available

- Video may not have captions enabled
- Try enabling "allowClientSignalFetch" for client-side extraction
- Check if video is age-restricted or private

### TikTok Blocking Requests

- Enable RapidAPI integration
- Reduce request frequency
- Use residential proxies (advanced)

### Instagram Login Required

- Instagram is actively blocking scrapers
- Consider using Instagram Basic Display API
- Implement manual recipe entry as fallback

### Rate Limit Exceeded

- Wait for rate limit reset
- Implement exponential backoff
- Consider upgrading API plans

### Low Extraction Success Rate

Check analytics for insights:

```typescript
const health = extractionAnalytics.getHealthStatus();
console.log(health.issues);
console.log(health.recommendations);
```

## Future Enhancements

1. **OCR Integration**: Extract text from video frames
2. **Computer Vision**: Ingredient detection in video frames
3. **Recipe Database Matching**: Match extracted content to known recipes
4. **User Corrections**: Learn from user edits to improve extraction
5. **Real-time Processing**: WebSocket-based progress updates
