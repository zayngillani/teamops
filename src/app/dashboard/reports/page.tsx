import { FileText, Download, Filter, Calendar as CalendarIcon, TrendingUp, Clock } from "lucide-react";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

export default async function ReportsPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;

  // RAW SQL WORKAROUND for Attendance status field
  const reportQuery = `
    SELECT 
      a.*, 
      u.name as "userName", 
      u.email as "userEmail", 
      u.role as "userRole"
    FROM "Attendance" a
    JOIN "User" u ON a."userId" = u.id
    WHERE a."status" = 'COMPLETED'
    ${user.role === 'admin' ? '' : 'AND a."userId" = $1::text'}
    ORDER BY a."startTime" DESC
    LIMIT 50
  `;
  
  const reportParams = user.role === 'admin' ? [] : [user.id];
  const logsRaw = await prisma.$queryRawUnsafe<any[]>(reportQuery, ...reportParams);

  // Map raw result to expected format
  const logs = logsRaw.map(log => ({
    ...log,
    user: {
      name: log.userName,
      email: log.userEmail,
      role: log.userRole
    }
  }));

  // Simple aggregation for the stats
  const totalHours = logs.reduce((acc: number, log: any) => acc + (log.totalWorkMs || 0), 0) / (1000 * 60 * 60);
  const totalDays = logs.length;

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div className="flex flex-col space-y-2">
          <h2 className="text-3xl font-bold font-display">Work Reports</h2>
          <p className="text-muted-foreground">Analyze attendance trends and export payroll data.</p>
        </div>
        <div className="flex gap-4">
          <button className="glass px-6 py-3 rounded-2xl font-bold flex items-center gap-2 hover:bg-white/10 transition-all text-sm">
            <Filter className="w-4 h-4" />
            Filter
          </button>
          <button className="bg-primary hover:bg-primary-hover text-white px-6 py-3 rounded-2xl font-bold flex items-center gap-2 transition-all active:scale-95 text-sm">
            <Download className="w-4 h-4" />
            Export Payroll
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[
          { label: "Total Work Hours", value: `${totalHours.toFixed(1)}h`, icon: Clock, color: "text-blue-500", bg: "bg-blue-500/10" },
          { label: "Active Days", value: totalDays.toString(), icon: CalendarIcon, color: "text-green-500", bg: "bg-green-500/10" },
          { label: "Break Time", value: `${(logs.reduce((acc: number, log: any) => acc + (log.totalBreakMs || 0), 0) / (1000 * 60 * 60)).toFixed(1)}h`, icon: TrendingUp, color: "text-purple-500", bg: "bg-purple-500/10" },
        ].map((stat, i) => (
          <div key={i} className="glass p-6 rounded-3xl space-y-4">
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

      <div className="glass rounded-3xl overflow-hidden">
        <div className="p-8 border-b border-border flex items-center justify-between bg-accent/10">
          <h3 className="text-xl font-bold flex items-center gap-2">
            <FileText className="w-5 h-5 text-primary" />
            Recent Daily Reports
          </h3>
          <p className="text-xs font-bold text-muted-foreground uppercase tracking-widest">Showing latest 50 reports</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="text-[10px] font-bold text-muted-foreground uppercase tracking-[0.2em] border-b border-border bg-slate-900/30">
                <th className="px-8 py-5">Date</th>
                {user.role === "admin" && <th className="px-8 py-5">Team Member</th>}
                <th className="px-8 py-5">Work Duration</th>
                <th className="px-8 py-5">Break Duration</th>
                <th className="px-8 py-5">Work Summary</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {logs.length > 0 ? logs.map((log: any) => (
                <tr key={log.id} className="hover:bg-white/[0.02] transition-colors">
                  <td className="px-8 py-6">
                    <p className="text-sm font-bold text-white">
                      {log.startTime.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                    </p>
                    <p className="text-[10px] text-muted-foreground">
                      {log.startTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </td>
                  {user.role === "admin" && (
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-[10px] font-bold text-primary">
                          {log.user.name?.[0]}
                        </div>
                        <span className="text-xs font-medium text-white">{log.user.name}</span>
                      </div>
                    </td>
                  )}
                  <td className="px-8 py-6 text-sm font-mono text-green-400 font-bold">
                    {(log.totalWorkMs / (1000 * 60 * 60)).toFixed(2)}h
                  </td>
                  <td className="px-8 py-6 text-sm font-mono text-orange-400 font-bold">
                    {(log.totalBreakMs / (1000 * 60 * 60)).toFixed(2)}h
                  </td>
                  <td className="px-8 py-6">
                    <p className="text-xs text-muted-foreground max-w-md line-clamp-2">
                      {log.report}
                    </p>
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={5} className="px-8 py-12 text-center text-muted-foreground italic text-sm">
                    No reports found for this period.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function cn(...classes: any[]) {
  return classes.filter(Boolean).join(" ");
}
