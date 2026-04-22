"use server";

import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { sendSlackNotification } from "@/lib/slack";

export async function createLinkedInPost(data: {
  content: string;
  mediaUrl?: string;
  scheduledAt?: Date;
}) {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  if (!user) throw new Error("Unauthorized");

  const post = await prisma.linkedInPost.create({
    data: {
      userId: user.id,
      content: data.content,
      mediaUrl: data.mediaUrl,
      scheduledAt: data.scheduledAt,
      status: "draft",
    },
  });

  revalidatePath("/dashboard/linkedin");
  return { success: true, post };
}

export async function updateLinkedInPost(
  postId: string,
  data: { content?: string; mediaUrl?: string; scheduledAt?: Date }
) {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  if (!user) throw new Error("Unauthorized");

  const post = await prisma.linkedInPost.findFirst({
    where: { id: postId, userId: user.id },
  });
  if (!post) throw new Error("Post not found");
  if (post.status !== "draft" && post.status !== "rejected") {
    throw new Error("Only draft or rejected posts can be edited");
  }

  const updated = await prisma.linkedInPost.update({
    where: { id: postId },
    data: { ...data, status: "draft" },
  });

  revalidatePath("/dashboard/linkedin");
  return { success: true, post: updated };
}

export async function deleteLinkedInPost(postId: string) {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  if (!user) throw new Error("Unauthorized");

  const post = await prisma.linkedInPost.findFirst({
    where: { id: postId, userId: user.id },
  });
  if (!post) throw new Error("Post not found");
  if (post.status !== "draft") throw new Error("Only draft posts can be deleted");

  await prisma.linkedInPost.delete({ where: { id: postId } });
  revalidatePath("/dashboard/linkedin");
  return { success: true };
}

export async function submitPostForApproval(postId: string) {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  if (!user) throw new Error("Unauthorized");

  const post = await prisma.linkedInPost.findFirst({
    where: { id: postId, userId: user.id },
  });
  if (!post) throw new Error("Post not found");
  if (post.status !== "draft") throw new Error("Only draft posts can be submitted");

  await prisma.linkedInPost.update({
    where: { id: postId },
    data: { status: "pending_approval" },
  });

  // Notify all admins
  const admins = await prisma.user.findMany({
    where: { role: "admin" },
    select: { slackId: true },
  });

  for (const admin of admins) {
    if (admin.slackId) {
      await sendSlackNotification({
        type: "LINKEDIN_PENDING",
        adminSlackId: admin.slackId,
        userName: user.name || "A team member",
        preview: post.content.substring(0, 150),
      });
    }
  }

  revalidatePath("/dashboard/linkedin");
  revalidatePath("/dashboard/admin/linkedin");
  return { success: true };
}

export async function approveLinkedInPost(postId: string) {
  const session = await getServerSession(authOptions);
  const admin = session?.user as any;
  if (admin?.role !== "admin") throw new Error("Unauthorized");

  const post = await prisma.linkedInPost.findUnique({
    where: { id: postId },
    include: { user: true },
  });
  if (!post) throw new Error("Post not found");
  if (post.status !== "pending_approval") throw new Error("Post is not pending approval");

  await prisma.linkedInPost.update({
    where: { id: postId },
    data: {
      status: post.scheduledAt ? "scheduled" : "approved",
      approvedBy: admin.id,
      approvedAt: new Date(),
    },
  });

  if (post.user.slackId) {
    await sendSlackNotification({
      type: "LINKEDIN_APPROVED",
      userSlackId: post.user.slackId,
      adminName: admin.name || "Admin",
      scheduledAt: post.scheduledAt,
    });
  }

  revalidatePath("/dashboard/admin/linkedin");
  revalidatePath("/dashboard/linkedin");
  return { success: true };
}

export async function rejectLinkedInPost(postId: string, reason: string) {
  const session = await getServerSession(authOptions);
  const admin = session?.user as any;
  if (admin?.role !== "admin") throw new Error("Unauthorized");

  const post = await prisma.linkedInPost.findUnique({
    where: { id: postId },
    include: { user: true },
  });
  if (!post) throw new Error("Post not found");

  await prisma.linkedInPost.update({
    where: { id: postId },
    data: { status: "rejected", rejectionReason: reason },
  });

  if (post.user.slackId) {
    await sendSlackNotification({
      type: "LINKEDIN_REJECTED",
      userSlackId: post.user.slackId,
      adminName: admin.name || "Admin",
      reason,
    });
  }

  revalidatePath("/dashboard/admin/linkedin");
  revalidatePath("/dashboard/linkedin");
  return { success: true };
}

export async function getUserLinkedInPosts() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  if (!user) throw new Error("Unauthorized");

  return prisma.linkedInPost.findMany({
    where: user.role === "admin" ? {} : { userId: user.id },
    orderBy: { createdAt: "desc" },
    take: 20,
  });
}

export async function getPendingLinkedInPosts() {
  const session = await getServerSession(authOptions);
  if ((session?.user as any)?.role !== "admin") throw new Error("Unauthorized");

  return prisma.linkedInPost.findMany({
    where: { status: "pending_approval" },
    include: { user: true },
    orderBy: { createdAt: "asc" },
  });
}

export async function getAllLinkedInPostsByStatus(status?: string) {
  const session = await getServerSession(authOptions);
  if ((session?.user as any)?.role !== "admin") throw new Error("Unauthorized");

  return prisma.linkedInPost.findMany({
    where: status ? { status: status as any } : {},
    include: { user: true },
    orderBy: { createdAt: "desc" },
    take: 50,
  });
}
