import { Github, GitCommit, Search, AlertCircle, Users as UsersIcon } from "lucide-react";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function GitHubPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;

  const isAdmin = user.role === "admin";
  
  const githubUsers = isAdmin ? await prisma.user.findMany({
    where: { featureToggles: { githubEnabled: true } },
    include: { featureToggles: true }
  }) : [];

  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    select: { githubUser: true }
  });

  return (
    <div className="max-w-5xl mx-auto space-y-8">
      <div className="flex flex-col space-y-2">
        <h2 className="text-3xl font-bold font-display">GitHub Integration</h2>
        <p className="text-muted-foreground">Track your code contributions and sync them with daily reports.</p>
      </div>

      {isAdmin ? (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="text-xl font-bold flex items-center gap-2">
              <UsersIcon className="w-5 h-5 text-primary" />
              Users with GitHub Access
            </h3>
            <span className="text-xs font-bold bg-primary/10 text-primary px-3 py-1 rounded-full uppercase">
              {githubUsers.length} Active
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {githubUsers.length > 0 ? githubUsers.map((u: any) => (
              <div key={u.id} className="glass p-6 rounded-3xl border border-white/5 flex items-center justify-between group hover:border-primary/30 transition-all">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center text-primary font-bold text-xl">
                    {u.name?.[0] || "U"}
                  </div>
                  <div>
                    <h4 className="font-bold text-white group-hover:text-primary transition-colors">{u.name}</h4>
                    <p className="text-xs text-muted-foreground">{u.email}</p>
                    {u.githubUser ? (
                      <p className="text-[10px] text-green-500 font-bold mt-1">@{u.githubUser}</p>
                    ) : (
                      <p className="text-[10px] text-orange-500 font-bold mt-1 italic">Username not set</p>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-green-500" />
                  <span className="text-[10px] font-bold uppercase text-green-500">Enabled</span>
                </div>
              </div>
            )) : (
              <div className="col-span-full glass p-12 text-center rounded-[40px] border border-white/5">
                <p className="text-muted-foreground italic">No users have GitHub access enabled.</p>
              </div>
            )}
          </div>
        </div>
      ) : !dbUser?.githubUser ? (
        <div className="glass p-12 text-center rounded-[40px] space-y-6 border border-white/5">
          <div className="w-20 h-20 bg-primary/10 rounded-full flex items-center justify-center mx-auto text-primary">
            <Github className="w-10 h-10" />
          </div>
          <div className="space-y-2">
            <h3 className="text-2xl font-bold">Connect your GitHub Account</h3>
            <p className="text-muted-foreground max-w-md mx-auto">
              Link your GitHub username to automatically track your commits and make daily reporting easier.
            </p>
          </div>
          
          <div className="max-w-md mx-auto bg-slate-900/50 p-4 rounded-2xl border border-border flex items-center gap-4">
            <Search className="w-5 h-5 text-muted-foreground shrink-0" />
            <input 
              type="text" 
              placeholder="Enter your GitHub username" 
              className="bg-transparent border-none outline-none text-white w-full"
            />
            <button className="bg-primary hover:bg-primary/90 text-white px-4 py-2 rounded-xl text-sm font-bold transition-all shrink-0">
              Connect
            </button>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="md:col-span-2 space-y-6">
            <h3 className="text-xl font-bold flex items-center gap-2">
              <GitCommit className="w-5 h-5 text-primary" />
              Today's Activity
            </h3>
            
            <div className="glass p-8 rounded-[40px] space-y-6">
              <div className="flex items-center gap-4 border-b border-border pb-6">
                <div className="w-12 h-12 bg-slate-800 rounded-full flex items-center justify-center">
                  <Github className="w-6 h-6 text-white" />
                </div>
                <div>
                  <p className="font-bold text-lg">@{dbUser.githubUser}</p>
                  <p className="text-xs text-green-500 font-bold flex items-center gap-1 mt-1">
                    <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                    Connected & Syncing
                  </p>
                </div>
              </div>

              <div className="p-4 bg-orange-500/10 border border-orange-500/20 rounded-2xl flex gap-3 text-orange-500">
                <AlertCircle className="w-5 h-5 shrink-0" />
                <p className="text-sm">
                  Commit syncing is currently in preview. To see real commits, ensure your repositories are public or the TeamOps GitHub App is installed in your organization.
                </p>
              </div>

              {/* Placeholder for actual commits */}
              <div className="space-y-4 pt-4 border-t border-border">
                <p className="text-sm text-muted-foreground italic text-center py-8">
                  Fetching recent commits from GitHub API...
                </p>
              </div>
            </div>
          </div>

          <div className="space-y-6">
            <div className="glass p-6 rounded-3xl space-y-4">
              <h4 className="font-bold">Sync Settings</h4>
              <div className="space-y-3">
                <div className="flex justify-between items-center text-sm">
                  <span className="text-muted-foreground">Auto-Sync</span>
                  <span className="font-bold text-primary">Enabled</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-muted-foreground">Sync Frequency</span>
                  <span className="font-bold">Every 1 hour</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
