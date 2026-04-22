import prisma from "./prisma";

export async function getUserToggles(userId: string) {
  return prisma.userFeatureToggle.findUnique({ where: { userId } });
}

export function defaultTogglesForRole(role: string) {
  return {
    githubEnabled: role === "developer" || role === "devops" || role === "admin",
    linkedinEnabled: role === "content_creator" || role === "admin",
    apiKeysEnabled: role === "developer" || role === "devops" || role === "admin",
    verificationEnabled: role === "developer" || role === "admin",
    breakTrackingEnabled: true,
    reportRemindersEnabled: true,
  };
}
