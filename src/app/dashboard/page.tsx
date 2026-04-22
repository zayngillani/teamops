import { getServerSession } from "next-auth";
import { redirect } from "next/navigation";
import { authOptions } from "@/lib/auth";
import prisma from "@/lib/prisma";
import { 
  Users, 
  Clock, 
  CheckCircle, 
  AlertCircle, 
  TrendingUp,
  Briefcase
} from "lucide-react";

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  const isAdmin = user?.role === "admin";

  if (!isAdmin) {
    redirect("/dashboard/attendance");
  }

  // Fetch stats based on role
  const totalTeam = isAdmin ? await prisma.user.count() : 0;
  const pendingLeaves = await prisma.leaveRequest.count({ 
    where: { 
      ...(isAdmin ? {} : { userId: user.id }),
      status: "PENDING" 
    } 
  });

  // RAW SQL WORKAROUND for Attendance status field
  const todayStart = new Date();
  todayStart.setHours(0,0,0,0);
  
  const attendanceQuery = isAdmin 
    ? `SELECT COUNT(*)::int as count FROM "Attendance" WHERE "startTime" >= $1::timestamp AND "status" IN ('WORKING', 'COMPLETED')`
    : `SELECT COUNT(*)::int as count FROM "Attendance" WHERE "startTime" >= $1::timestamp AND "status" IN ('WORKING', 'COMPLETED') AND "userId" = $2::text`;
  
  const attendanceParams = isAdmin ? [todayStart] : [todayStart, user.id];
  const todayAttendanceRaw = await prisma.$queryRawUnsafe<any[]>(attendanceQuery, ...attendanceParams);
  const todayAttendance = todayAttendanceRaw[0]?.count || 0;

  const recentReports = await prisma.dailyReport.findMany({
    where: isAdmin ? {} : { userId: user.id },
    take: 5,
    orderBy: { createdAt: "desc" },
    include: { user: true }
  });

  const stats = [
    ...(isAdmin ? [{ label: "Total Team", value: totalTeam?.toString() || "0", icon: Users, color: "text-blue-500", bg: "bg-blue-500/10" }] : []),
    { label: isAdmin ? "Today Active" : "Your Sessions", value: todayAttendance.toString(), icon: Clock, color: "text-green-500", bg: "bg-green-500/10" },
    { label: "Avg. Score", value: "92%", icon: TrendingUp, color: "text-purple-500", bg: "bg-purple-500/10" },
    { label: isAdmin ? "Team Pending Leaves" : "Your Pending Leaves", value: pendingLeaves.toString(), icon: AlertCircle, color: "text-orange-500", bg: "bg-orange-500/10" },
  ];

  return (
    <div className="space-y-8">
      <div className="flex flex-col space-y-2">
        <h2 className="text-3xl font-bold font-display">Hello, {user?.name?.split(' ')[0]}! 👋</h2>
        <p className="text-muted-foreground">
          {isAdmin ? "Here's what's happening with your team today." : "Welcome back to your workspace."}
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => (
          <div key={i} className="glass p-6 rounded-3xl space-y-4 hover:border-primary/50 transition-colors">
            <div className={`${stat.bg} ${stat.color} w-12 h-12 rounded-2xl flex items-center justify-center`}>
              <stat.icon className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground font-medium">{stat.label}</p>
              <h3 className="text-2xl font-bold">{stat.value}</h3>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 glass rounded-3xl p-8 space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="text-xl font-bold flex items-center gap-2">
              <Briefcase className="w-5 h-5 text-primary" />
              {isAdmin ? "Recent Team Activity" : "Your Recent Reports"}
            </h3>
            <button className="text-sm text-primary font-medium hover:underline">View All</button>
          </div>
          <div className="space-y-4">
            {recentReports.length > 0 ? recentReports.map((report: any) => (
              <div key={report.id} className="flex items-center space-x-4 p-4 hover:bg-accent/50 rounded-2xl transition-colors cursor-pointer">
                <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center text-xs font-bold uppercase">
                  {report.user.name?.[0] || "U"}
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium">
                    {isAdmin ? `${report.user.name} submitted a report` : "You submitted a report"}
                  </p>
                  <p className="text-xs text-muted-foreground">{new Date(report.createdAt).toLocaleTimeString()}</p>
                </div>
                <div className="text-xs font-bold text-green-500 bg-green-500/10 px-2 py-1 rounded-md uppercase">
                  {report.isVerified ? "VERIFIED" : "PENDING"}
                </div>
              </div>
            )) : (
              <p className="text-sm text-muted-foreground italic py-4 text-center">No recent activity found.</p>
            )}
          </div>
        </div>

        <div className="glass rounded-3xl p-8 space-y-6">
          <h3 className="text-xl font-bold">Important Dates</h3>
          <div className="space-y-6">
            <div className="relative pl-6 border-l-2 border-primary/30 py-1">
              <div className="absolute -left-1.5 top-0 w-3 h-3 rounded-full bg-primary" />
              <p className="text-xs font-bold text-primary uppercase">Current Period</p>
              <p className="text-sm font-medium">April 2026 Sprint</p>
            </div>
            <div className="relative pl-6 border-l-2 border-slate-700 py-1">
              <div className="absolute -left-1.5 top-0 w-3 h-3 rounded-full bg-slate-700" />
              <p className="text-xs font-bold text-muted-foreground uppercase">Next Review</p>
              <p className="text-sm font-medium">Monthly Performance</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
