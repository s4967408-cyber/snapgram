import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth.js';

interface RateEntry {
  timestamps: number[];
}

export class SlidingWindowLimiter {
  private store = new Map<string, RateEntry>();

  constructor(private readonly maxRequests: number, private readonly windowMs: number) {}

  consume(key: string, now = Date.now()): { allowed: boolean; remaining: number; retryAfterSeconds: number } {
    const entry = this.store.get(key) ?? { timestamps: [] };
    const cutoff = now - this.windowMs;
    entry.timestamps = entry.timestamps.filter((t) => t > cutoff);

    if (entry.timestamps.length >= this.maxRequests) {
      const oldest = entry.timestamps[0];
      const retryAfterSeconds = Math.max(1, Math.ceil((oldest + this.windowMs - now) / 1000));
      this.store.set(key, entry);
      return { allowed: false, remaining: 0, retryAfterSeconds };
    }

    entry.timestamps.push(now);
    this.store.set(key, entry);
    return {
      allowed: true,
      remaining: Math.max(0, this.maxRequests - entry.timestamps.length),
      retryAfterSeconds: 0
    };
  }
}

export function rateLimit(maxRequests: number, windowMs: number, scope = 'global') {
  const limiter = new SlidingWindowLimiter(maxRequests, windowMs);

  return (req: Request, res: Response, next: NextFunction) => {
    const authReq = req as AuthenticatedRequest;
    const identity = authReq.user?.id ?? req.ip ?? 'anonymous';
    const result = limiter.consume(`${scope}:${identity}`);

    res.setHeader('X-RateLimit-Limit', String(maxRequests));
    res.setHeader('X-RateLimit-Remaining', String(result.remaining));

    if (!result.allowed) {
      res.setHeader('Retry-After', String(result.retryAfterSeconds));
      return res.status(429).json({
        error: 'Too many requests. Please slow down.',
        retryAfterSeconds: result.retryAfterSeconds
      });
    }
    return next();
  };
}
