import { LeaveRequestForm } from "@/components/dashboard/leave-request-form";
import { History, Clock, CheckCircle2, XCircle } from "lucide-react";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { LeaveStatusButtons } from "@/components/dashboard/leave-status-buttons";

export default async function LeavesPage() {
  const session = await getServerSession(authOptions);
  const userRole = (session?.user as any)?.role;
  const isAdmin = userRole === "admin";

  const leaves = await prisma.leaveRequest.findMany({
    where: isAdmin ? {} : { userId: (session?.user as any)?.id },
    include: { user: true },
    orderBy: { createdAt: "desc" },
    take: 50
  });

  const pendingLeaves = leaves.filter((l: any) => l.status === "pending");
  const otherLeaves = leaves.filter((l: any) => l.status !== "pending");

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <div className="flex flex-col space-y-2">
        <h2 className="text-3xl font-bold font-display">Leave Management</h2>
        <p className="text-muted-foreground">Request time off and track your status.</p>
      </div>

      {!isAdmin && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="md:col-span-2">
            <LeaveRequestForm />
          </div>
          
          <div className="space-y-6">
            <div className="glass rounded-3xl p-6 space-y-4">
              <h4 className="font-bold">Leave Balance</h4>
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Annual Leave</span>
                  <span className="font-bold">12 / 15 days</span>
                </div>
                <div className="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                  <div className="bg-primary h-full w-[80%]" />
                </div>
                
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Sick Leave</span>
                  <span className="font-bold">2 / 5 days</span>
                </div>
                <div className="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                  <div className="bg-orange-500 h-full w-[40%]" />
                </div>
              </div>
            </div>

            <div className="glass rounded-3xl p-6 bg-primary/5 border-primary/20">
              <h4 className="font-bold text-sm mb-2">Need Help?</h4>
              <p className="text-xs text-muted-foreground">
                For urgent leave requests, please contact HR directly after submitting your form.
              </p>
            </div>
          </div>
        </div>
      )}

      <div className="glass rounded-3xl p-8 space-y-6">
        <h3 className="text-xl font-bold flex items-center gap-2">
          <History className="w-5 h-5 text-primary" />
          Request History
        </h3>

        <div className="space-y-4">
          {leaves.length > 0 ? leaves.map((leave: any) => (
            <div key={leave.id} className="flex items-center justify-between p-6 border border-border rounded-2xl hover:bg-accent/30 transition-all">
              <div className="space-y-1">
                {isAdmin && (
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-sm font-bold text-white">{leave.user.name}</span>
                    <span className="text-[10px] bg-white/5 px-2 py-0.5 rounded-md text-muted-foreground uppercase tracking-widest font-bold">
                      {leave.user.role}
                    </span>
                    <span className="text-[10px] bg-primary/10 px-2 py-0.5 rounded-md text-primary uppercase tracking-widest font-bold">
                      {leave.user.userType}
                    </span>
                  </div>
                )}
                <p className="font-bold">
                  {new Date(leave.startDate).toLocaleDateString()} - {new Date(leave.endDate).toLocaleDateString()}
                </p>
                <p className="text-sm text-muted-foreground">{leave.reason}</p>
              </div>
              <div className="flex items-center gap-4">
                {leave.status === "APPROVED" ? (
                  <div className="flex items-center gap-2 text-green-500 bg-green-500/10 px-3 py-1 rounded-full text-xs font-bold">
                    <CheckCircle2 className="w-4 h-4" />
                    APPROVED
                  </div>
                ) : leave.status === "PENDING" ? (
                  isAdmin ? (
                    <LeaveStatusButtons leaveId={leave.id} />
                  ) : (
                    <div className="flex items-center gap-2 text-orange-500 bg-orange-500/10 px-3 py-1 rounded-full text-xs font-bold">
                      <Clock className="w-4 h-4" />
                      PENDING
                    </div>
                  )
                ) : (
                  <div className="flex items-center gap-2 text-destructive bg-destructive/10 px-3 py-1 rounded-full text-xs font-bold">
                    <XCircle className="w-4 h-4" />
                    REJECTED
                  </div>
                )}
              </div>
            </div>
          )) : (
            <div className="text-center py-8 text-muted-foreground italic">
              No leave requests found.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
