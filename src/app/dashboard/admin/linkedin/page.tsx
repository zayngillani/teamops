import { CheckCircle2, AlertCircle, Clock, XCircle } from "lucide-react";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";
import { AdminLinkedInClient } from "./client-page";

export default async function AdminLinkedInApprovals() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;

  if (user?.role !== "admin") {
    redirect("/dashboard");
  }

  // Fetch pending posts
  const pendingPosts = await prisma.linkedInPost.findMany({
    where: { status: "pending_approval" },
    include: { user: true },
    orderBy: { createdAt: "asc" },
  });

  // Fetch recently resolved posts (approved or rejected)
  const resolvedPosts = await prisma.linkedInPost.findMany({
    where: { status: { in: ["approved", "scheduled", "rejected", "published"] } },
    include: { user: true },
    orderBy: { updatedAt: "desc" },
    take: 20,
  });

  return (
    <div className="max-w-5xl mx-auto space-y-8">
      <div className="flex flex-col space-y-2">
        <h2 className="text-3xl font-bold font-display">LinkedIn Approvals</h2>
        <p className="text-muted-foreground">Review and manage content submitted by the team.</p>
      </div>

      <AdminLinkedInClient pendingPosts={pendingPosts} resolvedPosts={resolvedPosts} />
    </div>
  );
}
