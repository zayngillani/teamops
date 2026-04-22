"use server";

import prisma from "@/lib/prisma";
import bcrypt from "bcryptjs";
import { revalidatePath } from "next/cache";
import { defaultTogglesForRole } from "@/lib/toggles";

export async function createUser(formData: FormData) {
  const name = formData.get("name") as string;
  const email = formData.get("email") as string;
  const password = formData.get("password") as string;
  const role = formData.get("role") as any;
  const status = (formData.get("status") as any) || "active";
  const userType = formData.get("userType") as any;
  const githubUser = formData.get("githubUser") as string;
  const slackId = formData.get("slackId") as string;
  const joinDate = formData.get("joinDate")
    ? new Date(formData.get("joinDate") as string)
    : new Date();
  const canOutsideAccess = formData.get("canOutsideAccess") === "true";

  if (!email || !password || !role) {
    throw new Error("Missing required fields");
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  let newUser;
  try {
    newUser = await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
        role,
        status,
        userType,
        githubUser,
        slackId,
        joinDate,
        canOutsideAccess,
      },
    });
  } catch (error: any) {
    if (error.code === "P2002") {
      throw new Error("A user with this email already exists.");
    }
    throw error;
  }

  // Auto-create feature toggles using raw SQL to bypass stale Prisma Client validation
  // Default: all features OFF as requested
  await prisma.$executeRawUnsafe(`
    INSERT INTO "UserFeatureToggle" ("id", "userId", "githubEnabled", "linkedinEnabled", "apiKeysEnabled", "verificationEnabled", "breakTrackingEnabled", "reportRemindersEnabled", "updatedAt")
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
  `,
    Math.random().toString(36).substring(7),
    newUser.id,
    false, // githubEnabled
    false, // linkedinEnabled
    false, // apiKeysEnabled
    false, // verificationEnabled
    true,  // breakTrackingEnabled (internal feature)
    true   // reportRemindersEnabled (internal feature)
  );

  revalidatePath("/dashboard/users");
}

export async function updateUser(id: string, formData: FormData) {
  const name = formData.get("name") as string;
  const email = formData.get("email") as string;
  const role = formData.get("role") as any;
  const status = formData.get("status") as any;
  const userType = formData.get("userType") as any;
  const githubUser = formData.get("githubUser") as string;
  const slackId = formData.get("slackId") as string;
  const canOutsideAccess = formData.get("canOutsideAccess") === "true";
  const password = formData.get("password") as string;
  const githubEnabled = formData.get("githubEnabled") === "true";
  const linkedinEnabled = formData.get("linkedinEnabled") === "true";
  const apiKeysEnabled = formData.get("apiKeysEnabled") === "true";
  const verificationEnabled = formData.get("verificationEnabled") === "true";

  const updateData: any = {
    name,
    email,
    role,
    status,
    userType,
    githubUser,
    slackId,
    canOutsideAccess,
  };

  if (password && password.trim() !== "") {
    updateData.password = await bcrypt.hash(password, 10);
  }

  await prisma.user.update({
    where: { id },
    data: updateData,
  });

  // Update feature toggles using raw SQL to bypass stale Prisma Client validation
  await prisma.$executeRawUnsafe(`
    INSERT INTO "UserFeatureToggle" ("id", "userId", "githubEnabled", "linkedinEnabled", "apiKeysEnabled", "verificationEnabled", "breakTrackingEnabled", "reportRemindersEnabled", "updatedAt")
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
    ON CONFLICT ("userId") DO UPDATE SET
      "githubEnabled" = EXCLUDED."githubEnabled",
      "linkedinEnabled" = EXCLUDED."linkedinEnabled",
      "apiKeysEnabled" = EXCLUDED."apiKeysEnabled",
      "verificationEnabled" = EXCLUDED."verificationEnabled",
      "updatedAt" = NOW()
  `, 
    Math.random().toString(36).substring(7), // Random ID for create
    id, 
    githubEnabled, 
    linkedinEnabled, 
    apiKeysEnabled,
    verificationEnabled,
    true, // default breakTrackingEnabled
    true  // default reportRemindersEnabled
  );

  revalidatePath("/dashboard/users");
  revalidatePath("/dashboard/admin/toggles");
}

export async function deleteUser(id: string) {
  await prisma.user.delete({
    where: { id },
  });

  revalidatePath("/dashboard/users");
}

export async function updateUserToggles(
  userId: string,
  toggles: {
    githubEnabled?: boolean;
    linkedinEnabled?: boolean;
    apiKeysEnabled?: boolean;
    verificationEnabled?: boolean;
    breakTrackingEnabled?: boolean;
    reportRemindersEnabled?: boolean;
  }
) {
  // Update feature toggles using raw SQL to bypass stale Prisma Client validation
  await prisma.$executeRawUnsafe(`
    INSERT INTO "UserFeatureToggle" ("id", "userId", "githubEnabled", "linkedinEnabled", "apiKeysEnabled", "verificationEnabled", "breakTrackingEnabled", "reportRemindersEnabled", "updatedAt")
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
    ON CONFLICT ("userId") DO UPDATE SET
      "githubEnabled" = COALESCE(EXCLUDED."githubEnabled", "UserFeatureToggle"."githubEnabled"),
      "linkedinEnabled" = COALESCE(EXCLUDED."linkedinEnabled", "UserFeatureToggle"."linkedinEnabled"),
      "apiKeysEnabled" = COALESCE(EXCLUDED."apiKeysEnabled", "UserFeatureToggle"."apiKeysEnabled"),
      "verificationEnabled" = COALESCE(EXCLUDED."verificationEnabled", "UserFeatureToggle"."verificationEnabled"),
      "breakTrackingEnabled" = COALESCE(EXCLUDED."breakTrackingEnabled", "UserFeatureToggle"."breakTrackingEnabled"),
      "reportRemindersEnabled" = COALESCE(EXCLUDED."reportRemindersEnabled", "UserFeatureToggle"."reportRemindersEnabled"),
      "updatedAt" = NOW()
  `,
    Math.random().toString(36).substring(7),
    userId,
    toggles.githubEnabled ?? null,
    toggles.linkedinEnabled ?? null,
    toggles.apiKeysEnabled ?? null,
    toggles.verificationEnabled ?? null,
    toggles.breakTrackingEnabled ?? null,
    toggles.reportRemindersEnabled ?? null
  );

  revalidatePath("/dashboard/settings");
  revalidatePath("/dashboard/admin/toggles");
}

export async function getAllUsersWithToggles() {
  return prisma.user.findMany({
    include: { featureToggles: true },
    orderBy: { createdAt: "desc" },
  });
}
