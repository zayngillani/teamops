import { AttendanceTracker } from "@/components/dashboard/attendance-tracker";
import { History, Calendar, Info, Users, ArrowRight, Search } from "lucide-react";
import Link from "next/link";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { MonthlySummary } from "@/components/dashboard/monthly-summary";
import { AttendanceSearch } from "@/components/dashboard/attendance-search";

export default async function AttendancePage({
  searchParams,
}: {
  searchParams: { userId?: string; q?: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session?.user) return null;

  const userRole = (session?.user as any)?.role;
  const isAdmin = userRole === "admin";
  const targetUserId = (isAdmin && searchParams.userId) ? searchParams.userId : (session?.user as any)?.id;

  const todayStart = new Date();
  todayStart.setHours(0,0,0,0);

  const [user, rawLogs, teamDataRaw] = await Promise.all([
    prisma.user.findUnique({ where: { id: targetUserId } }),
    prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "Attendance" WHERE "userId" = $1::text ORDER BY "startTime" ASC`, 
      targetUserId
    ),
    isAdmin ? prisma.$queryRawUnsafe<any[]>(`
      SELECT 
        u.*, 
        a.id as "att_id", 
        a.status as "att_status", 
        a."startTime" as "att_startTime",
        a."endTime" as "att_endTime"
      FROM "User" u
      LEFT JOIN (
        SELECT DISTINCT ON ("userId") *
        FROM "Attendance"
        WHERE "startTime" >= $1::timestamp
        ORDER BY "userId", "startTime" DESC
      ) a ON u.id = a."userId"
      ORDER BY u.name ASC
    `, todayStart) : Promise.resolve([])
  ]);

  // Map team data to match the expected structure
  const rawAllUsers = teamDataRaw.map(u => ({
    ...u,
    attendance: u.att_id ? [{
      id: u.att_id,
      status: u.att_status,
      startTime: u.att_startTime,
      endTime: u.att_endTime
    }] : []
  }));

  const allUsers = searchParams.q 
    ? rawAllUsers.filter(u => u.name?.toLowerCase().includes(searchParams.q!.toLowerCase()) || u.role?.toLowerCase().includes(searchParams.q!.toLowerCase()))
    : rawAllUsers;

  const summaries = rawLogs.map((log: any) => {
    const start = new Date(log.startTime);
    const end = log.endTime ? new Date(log.endTime) : null;
    const workMs = log.totalWorkMs || 0;
    const breakMs = log.totalBreakMs || 0;

    return {
      date: start.toLocaleDateString(),
      checkIn: start,
      checkOut: end,
      workMs,
      breakMs,
    };
  }).reverse();

  const formatDuration = (ms: number) => {
    if (!ms || ms <= 0) return "—";
    const hours = Math.floor(ms / 3600000);
    const minutes = Math.floor((ms % 3600000) / 60000);
    const seconds = Math.floor((ms % 60000) / 1000);
    
    if (hours > 0) return `${hours}h ${minutes}m`;
    if (minutes > 0) return `${minutes}m ${seconds}s`;
    return `${seconds}s`;
  };

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      <div className="flex flex-col space-y-2">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            {isAdmin && searchParams.userId && (
              <Link href="/dashboard/attendance" className="p-2 hover:bg-accent rounded-full transition-colors">
                <ArrowRight className="w-5 h-5 rotate-180" />
              </Link>
            )}
            <h2 className="text-3xl font-bold font-display">
              {isAdmin && searchParams.userId ? `${user?.name}'s Attendance` : (isAdmin ? "Team Attendance" : "My Attendance")}
            </h2>
          </div>
          
          {isAdmin && !searchParams.userId && <AttendanceSearch />}
        </div>
        <p className="text-muted-foreground">
          {isAdmin && !searchParams.userId ? "Monitor and manage team activity." : "Manage and track work performance."}
        </p>
      </div>

      {isAdmin && !searchParams.userId ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {allUsers.map((u: any) => {
            const lastSession = u.attendance[0];
            const isActive = lastSession && !lastSession.endTime;
            
            return (
              <Link 
                key={u.id} 
                href={`/dashboard/attendance?userId=${u.id}`}
                className="glass p-6 rounded-3xl hover:border-primary/50 transition-all group"
              >
                <div className="flex items-center justify-between mb-4">
                  <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center text-primary font-bold">
                    {u.name?.[0] || "U"}
                  </div>
                  <div className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase ${isActive ? 'bg-green-500/10 text-green-500' : 'bg-slate-500/10 text-slate-500'}`}>
                    {isActive ? "Working" : "Offline"}
                  </div>
                </div>
                <div>
                  <h4 className="font-bold group-hover:text-primary transition-colors">{u.name}</h4>
                  <p className="text-xs text-muted-foreground">{u.role}</p>
                </div>
                <div className="mt-4 pt-4 border-t border-white/5 flex items-center justify-between text-xs">
                  <span className="text-muted-foreground">Last Action</span>
                  <span className="font-medium">
                    {lastSession ? new Date(lastSession.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "N/A"}
                  </span>
                </div>
              </Link>
            );
          })}
        </div>
      ) : (
        <>
          <MonthlySummary userId={targetUserId} />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="md:col-span-2">
              {/* Only show tracker for current user's own page or if admin wants to see their own */}
              {targetUserId === (session?.user as any)?.id && !isAdmin && <AttendanceTracker />}
              
              {isAdmin && searchParams.userId && (
                <div className="glass rounded-3xl p-8 bg-primary/5 border-primary/20 flex items-center justify-between">
                  <div className="space-y-1">
                    <h4 className="font-bold">Administrative View</h4>
                    <p className="text-sm text-muted-foreground">You are viewing {user?.name}'s logs.</p>
                  </div>
                  <button className="bg-primary hover:bg-primary-hover text-white px-4 py-2 rounded-xl text-sm font-bold shadow-lg shadow-primary/20 transition-all">
                    Download PDF Report
                  </button>
                </div>
              )}
            </div>
            
            <div className="glass rounded-3xl p-6 space-y-6 self-start">
              <h4 className="font-bold flex items-center gap-2">
                <Info className="w-4 h-4 text-primary" />
                Attendance Summary
              </h4>
              <div className="space-y-4">
                <div className="p-4 bg-slate-800/50 rounded-2xl border border-border">
                  <p className="text-xs text-muted-foreground uppercase mb-1">Status</p>
                  <p className="text-sm font-bold flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                    {user?.status}
                  </p>
                </div>
                <div className="p-4 bg-slate-800/50 rounded-2xl border border-border">
                  <p className="text-xs text-muted-foreground uppercase mb-1">Role</p>
                  <p className="text-sm font-bold">{user?.role}</p>
                </div>
              </div>
            </div>
          </div>

          <div className="glass rounded-3xl p-8 space-y-6">
            <div className="flex items-center justify-between">
              <h3 className="text-xl font-bold flex items-center gap-2">
                <History className="w-5 h-5 text-primary" />
                Attendance History
              </h3>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead>
                  <tr className="text-xs font-bold text-muted-foreground uppercase tracking-wider border-b border-border">
                    <th className="px-4 py-3">Date</th>
                    <th className="px-4 py-3">Check In</th>
                    <th className="px-4 py-3">Check Out</th>
                    <th className="px-4 py-3">Break Time</th>
                    <th className="px-4 py-3">Total Work</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {summaries.length > 0 ? summaries.map((day: any, i: number) => (
                    <tr key={i} className="text-sm hover:bg-accent/30 transition-colors">
                      <td className="px-4 py-4 font-medium">{day.date}</td>
                      <td className="px-4 py-4">{day.checkIn.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</td>
                      <td className="px-4 py-4">
                        {day.checkOut ? day.checkOut.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : (
                          <span className="text-primary animate-pulse font-bold">Active</span>
                        )}
                      </td>
                      <td className="px-4 py-4 text-orange-400">
                        {formatDuration(day.breakMs)}
                      </td>
                      <td className="px-4 py-4 font-bold text-green-400">
                        {formatDuration(day.workMs)}
                      </td>
                    </tr>
                  )) : (
                    <tr>
                      <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground italic">No attendance records found.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
