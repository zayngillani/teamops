import { ShieldAlert } from "lucide-react";
import prisma from "@/lib/prisma";
import AddUserModal from "@/components/AddUserModal";
import { UserTable } from "@/components/dashboard/user-table";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function UsersPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;

  if (user?.role !== "admin") {
    redirect("/dashboard");
  }

  const users: any[] = await prisma.user.findMany({
    include: { featureToggles: true },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      <div className="flex items-center justify-between">
        <div className="flex flex-col space-y-2">
          <h2 className="text-3xl font-bold font-display">User Management</h2>
          <p className="text-muted-foreground">Manage team members and their roles.</p>
        </div>
        <AddUserModal />
      </div>

      <UserTable users={users} />

    </div>
  );
}
