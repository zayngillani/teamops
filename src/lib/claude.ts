import prisma from "./prisma";

export async function getClaudeKey() {
  const config = await prisma.systemConfig.findUnique({
    where: { id: "config" },
  });

  if (!config || !config.claudeToken || !config.tokenExpiry) {
    return null;
  }

  const now = new Date();
  if (now > config.tokenExpiry) {
    return null; // Key expired
  }

  return config.claudeToken;
}

export async function rotateClaudeKey(newToken: string) {
  const expiry = new Date();
  expiry.setHours(expiry.getHours() + 8);

  return await prisma.systemConfig.upsert({
    where: { id: "config" },
    update: {
      claudeToken: newToken,
      tokenExpiry: expiry,
      lastRotation: new Date(),
    },
    create: {
      id: "config",
      claudeToken: newToken,
      tokenExpiry: expiry,
      lastRotation: new Date(),
    },
  });
}

export async function verifyReport(report: string, commits: any[]) {
  const key = await getClaudeKey();
  if (!key) throw new Error("Claude API key not available or expired");

  // Logic to call Claude API and compare report with commits
  // This would use the Anthropic SDK
  
  return {
    score: 85,
    analysis: "The report matches 85% of the commit activity. Some tasks mentioned (e.g., database optimization) are not reflected in the commits.",
  };
}
