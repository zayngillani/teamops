"use server";

import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { sendSlackNotification } from "@/lib/slack";

export async function submitLeaveRequest(formData: {
  startDate: string;
  endDate: string;
  leaveType: string;
  reason: string;
}) {
  const session = await getServerSession(authOptions);
  if (!session?.user) throw new Error("Unauthorized");

  const userId = (session.user as any).id;
  const userName = session.user.name || "A team member";

  const leave = await prisma.leaveRequest.create({
    data: {
      userId,
      startDate: new Date(formData.startDate),
      endDate: new Date(formData.endDate),
      leaveType: formData.leaveType,
      reason: formData.reason,
      status: "PENDING",
    },
  });

  // Slack Notification
  await sendSlackNotification({
    type: "LEAVE_REQUEST",
    user: userName,
    start: formData.startDate,
    end: formData.endDate,
    reason: formData.reason,
  });

  revalidatePath("/dashboard/leaves");
  return leave;
}

export async function updateLeaveStatus(id: string, status: "APPROVED" | "REJECTED") {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;

  if (user?.role !== "admin") throw new Error("Only admins can approve leaves.");

  const leave = await prisma.leaveRequest.update({
    where: { id },
    data: {
      status,
      approvedBy: user.name,
    },
  });

  revalidatePath("/dashboard/leaves");
  return leave;
}
