import { z } from "zod";

export const createProfileSchema = z.object({
  fullName: z
    .string()
    .min(2, "Enter your name")
    .max(80, "Keep your name under 80 characters"),
  email: z.string().email("Enter a valid email address")
});

export const verifyProfileCodeSchema = z.object({
  token: z
    .string()
    .trim()
    .min(6, "Enter the 6-digit code")
    .max(6, "Enter the 6-digit code")
    .regex(/^\d{6}$/, "Enter the 6-digit code")
});

export type CreateProfileValues = z.infer<typeof createProfileSchema>;
export type VerifyProfileCodeValues = z.infer<typeof verifyProfileCodeSchema>;
