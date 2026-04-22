import { Briefcase, Users, Plus, ExternalLink, Calendar, Search } from "lucide-react";
import prisma from "@/lib/prisma";
import Link from "next/link";

export default async function RecruitmentPage() {
  const [jobs, applications] = await Promise.all([
    prisma.jobPost.findMany({ orderBy: { createdAt: "desc" } }),
    prisma.application.findMany({
      take: 10,
      orderBy: { createdAt: "desc" },
      include: { job: true }
    })
  ]);

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div className="flex flex-col space-y-2">
          <h2 className="text-3xl font-bold font-display">Recruitment Pipeline</h2>
          <p className="text-muted-foreground">Manage open positions and track applicants.</p>
        </div>
        <button className="bg-primary hover:bg-primary-hover text-white px-6 py-3 rounded-2xl font-bold flex items-center gap-2 transition-all active:scale-95">
          <Plus className="w-5 h-5" />
          Post New Job
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { label: "Active Jobs", value: jobs.length.toString(), icon: Briefcase, color: "text-blue-500", bg: "bg-blue-500/10" },
          { label: "Total Applicants", value: applications.length.toString(), icon: Users, color: "text-green-500", bg: "bg-green-500/10" },
          { label: "Interviews Today", value: "3", icon: Calendar, color: "text-purple-500", bg: "bg-purple-500/10" },
          { label: "Hire Rate", value: "12%", icon: Search, color: "text-orange-500", bg: "bg-orange-500/10" },
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

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="glass rounded-3xl p-8 space-y-6">
          <h3 className="text-xl font-bold flex items-center gap-2">
            <Briefcase className="w-5 h-5 text-primary" />
            Active Job Posts
          </h3>
          <div className="space-y-4">
            {jobs.length > 0 ? jobs.map((job: any) => (
              <div key={job.id} className="flex items-center justify-between p-4 border border-border rounded-2xl hover:bg-accent/30 transition-all group">
                <div>
                  <h4 className="font-bold text-white group-hover:text-primary transition-colors">{job.title}</h4>
                  <p className="text-xs text-muted-foreground">{job.department} • {job.status}</p>
                </div>
                <button className="p-2 hover:bg-slate-800 rounded-lg">
                  <ExternalLink className="w-4 h-4 text-muted-foreground" />
                </button>
              </div>
            )) : (
              <p className="text-sm text-muted-foreground italic py-4">No active job posts.</p>
            )}
          </div>
        </div>

        <div className="glass rounded-3xl p-8 space-y-6">
          <h3 className="text-xl font-bold flex items-center gap-2">
            <Users className="w-5 h-5 text-primary" />
            Recent Applications
          </h3>
          <div className="space-y-4">
            {applications.length > 0 ? applications.map((app: any) => (
              <div key={app.id} className="flex items-center justify-between p-4 border border-border rounded-2xl hover:bg-accent/30 transition-all">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center text-xs font-bold">
                    {app.name[0]}
                  </div>
                  <div>
                    <h4 className="font-bold text-sm">{app.name}</h4>
                    <p className="text-[10px] text-muted-foreground uppercase tracking-wider">{app.job.title}</p>
                  </div>
                </div>
                <div className={cn(
                  "text-[10px] font-bold px-2 py-1 rounded-md",
                  app.status === "NEW" ? "bg-blue-500/10 text-blue-500" :
                  app.status === "REJECTED" ? "bg-destructive/10 text-destructive" :
                  "bg-green-500/10 text-green-500"
                )}>
                  {app.status}
                </div>
              </div>
            )) : (
              <p className="text-sm text-muted-foreground italic py-4">No recent applications.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function cn(...classes: any[]) {
  return classes.filter(Boolean).join(" ");
}
