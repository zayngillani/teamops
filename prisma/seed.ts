import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  const pass = await bcrypt.hash("admin123", 10);

  console.log("Seeding database...");

  // 1. Super Admin
  const admin = await prisma.user.upsert({
    where: { email: "admin@teamops.com" },
    update: { password: pass, status: "active", role: "admin" },
    create: {
      email: "admin@teamops.com",
      name: "Super Admin",
      password: pass,
      role: "admin",
      status: "active",
      userType: "DEVOPS",
      joinDate: new Date(),
    },
  });

  await prisma.userFeatureToggle.upsert({
    where: { userId: admin.id },
    update: {},
    create: {
      userId: admin.id,
      githubEnabled: true,
      linkedinEnabled: true,
      apiKeysEnabled: true,
      verificationEnabled: true,
      breakTrackingEnabled: true,
      reportRemindersEnabled: true,
    } as any,
  });

  // 2. Developer
  const dev = await prisma.user.upsert({
    where: { email: "dev@teamops.com" },
    update: {},
    create: {
      email: "dev@teamops.com",
      name: "Dev User",
      password: pass,
      role: "developer",
      status: "active",
      userType: "DEVELOPER",
      joinDate: new Date(),
    },
  });

  await prisma.userFeatureToggle.upsert({
    where: { userId: dev.id },
    update: {},
    create: {
      userId: dev.id,
      githubEnabled: true,
      linkedinEnabled: false,
      apiKeysEnabled: true,
      verificationEnabled: true,
      breakTrackingEnabled: true,
      reportRemindersEnabled: true,
    } as any,
  });

  // 3. Content Creator
  const creator = await prisma.user.upsert({
    where: { email: "content@teamops.com" },
    update: {},
    create: {
      email: "content@teamops.com",
      name: "Content Creator",
      password: pass,
      role: "content_creator",
      status: "active",
      joinDate: new Date(),
    },
  });

  await prisma.userFeatureToggle.upsert({
    where: { userId: creator.id },
    update: {},
    create: {
      userId: creator.id,
      githubEnabled: false,
      linkedinEnabled: true,
      apiKeysEnabled: false,
      verificationEnabled: false,
      breakTrackingEnabled: true,
      reportRemindersEnabled: true,
    } as any,
  });

  // 4. Whitelisted IP
  await prisma.ipManagement.upsert({
    where: { ipAddress: "127.0.0.1" },
    update: {},
    create: {
      ipAddress: "127.0.0.1",
      status: true,
      description: "Localhost Access",
    },
  });

  // 5. Sample Job Post
  const job = await prisma.jobPost.upsert({
    where: { id: "seed-job-1" },
    update: {},
    create: {
      id: "seed-job-1",
      title: "Senior Full Stack Developer",
      department: "Engineering",
      description: "We are looking for a Senior Next.js / TypeScript developer...",
    },
  });

  // 6. Sample Application
  await prisma.application.upsert({
    where: { id: "seed-app-1" },
    update: {},
    create: {
      id: "seed-app-1",
      jobId: job.id,
      name: "Ali Gillani",
      email: "ali@example.com",
      status: "NEW",
    },
  });

  console.log("✅ Seed complete!");
  console.log("   admin@teamops.com / admin123");
  console.log("   dev@teamops.com / admin123");
  console.log("   content@teamops.com / admin123");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
