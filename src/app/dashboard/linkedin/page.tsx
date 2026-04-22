import { Linkedin, Send, Clock, CheckCircle2, AlertCircle, Plus, LayoutGrid, XCircle } from "lucide-react";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { LinkedInCreatorClient } from "./client-page";
import { cn } from "@/lib/utils";

export default async function LinkedInPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  const isAdmin = user.role === "admin";

  const linkedinUsers = isAdmin ? await prisma.user.findMany({
    where: { featureToggles: { linkedinEnabled: true } },
    include: { featureToggles: true }
  }) : [];

  const posts = await prisma.linkedInPost.findMany({
    where: user.role === "admin" ? {} : { userId: user.id },
    orderBy: { createdAt: "desc" },
    take: 20,
    include: { user: true }
  });

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div className="flex flex-col space-y-2">
          <h2 className="text-3xl font-bold font-display">LinkedIn Content Manager</h2>
          <p className="text-muted-foreground">Draft, schedule, and track your professional outreach.</p>
        </div>
      </div>

      {isAdmin && (
        <div className="space-y-4">
          <h3 className="text-xl font-bold flex items-center gap-2 text-[#0077B5]">
            <LayoutGrid className="w-5 h-5" />
            Users with LinkedIn Access
          </h3>
          <div className="flex flex-wrap gap-3">
            {linkedinUsers.length > 0 ? linkedinUsers.map((u: any) => (
              <div key={u.id} className="glass px-4 py-3 rounded-2xl border border-white/5 flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-[#0077B5]/10 flex items-center justify-center text-[#0077B5] font-bold text-sm">
                  {u.name?.[0] || "U"}
                </div>
                <div>
                  <p className="text-sm font-bold text-white">{u.name}</p>
                  <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-wider">{u.userType || "OUTREACH"}</p>
                </div>
              </div>
            )) : (
              <p className="text-sm text-muted-foreground italic">No users have LinkedIn access enabled.</p>
            )}
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {[
          { label: "Published", value: posts.filter((p: any) => p.status === "published").length.toString(), icon: CheckCircle2, color: "text-green-500", bg: "bg-green-500/10" },
          { label: "Approved/Scheduled", value: posts.filter((p: any) => p.status === "approved" || p.status === "scheduled").length.toString(), icon: Clock, color: "text-blue-500", bg: "bg-blue-500/10" },
          { label: "Pending Approval", value: posts.filter((p: any) => p.status === "pending_approval").length.toString(), icon: Send, color: "text-purple-500", bg: "bg-purple-500/10" },
          { label: "Drafts", value: posts.filter((p: any) => p.status === "draft" || p.status === "rejected").length.toString(), icon: LayoutGrid, color: "text-slate-500", bg: "bg-slate-500/10" },
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-6">
          <h3 className="text-xl font-bold flex items-center gap-2">
            <Clock className="w-5 h-5 text-[#0077B5]" />
            Recent Content
          </h3>
          <div className="space-y-4">
            {posts.length > 0 ? posts.map((post: any) => (
              <div key={post.id} className={cn("glass rounded-3xl p-6 space-y-4 border transition-all group", 
                post.status === "rejected" ? "border-orange-500/30 bg-orange-500/5" : "border-white/5 hover:border-[#0077B5]/30"
              )}>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className={cn(
                      "text-[10px] font-bold px-2 py-1 rounded-md uppercase tracking-wider",
                      post.status === "published" ? "bg-green-500/10 text-green-500" :
                      post.status === "scheduled" || post.status === "approved" ? "bg-blue-500/10 text-blue-500" :
                      post.status === "pending_approval" ? "bg-purple-500/10 text-purple-500" :
                      post.status === "rejected" || post.status === "failed" ? "bg-orange-500/10 text-orange-500" :
                      "bg-slate-500/10 text-slate-400"
                    )}>
                      {post.status.replace("_", " ")}
                    </span>
                    <span className="text-[10px] text-muted-foreground font-medium flex items-center gap-1">
                      {user.role === "admin" && <span className="text-white border-r border-border pr-2 mr-1">{post.user?.name}</span>}
                      {new Date(post.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                </div>
                
                <p className="text-sm text-slate-300 leading-relaxed whitespace-pre-wrap">
                  {post.content}
                </p>

                {post.status === "rejected" && post.rejectionReason && (
                  <div className="pt-4 mt-4 border-t border-orange-500/20">
                    <p className="text-xs font-bold text-orange-500 flex items-center gap-1">
                      <XCircle className="w-3.5 h-3.5" /> Rejection Reason
                    </p>
                    <p className="text-sm text-orange-400/80 mt-1">{post.rejectionReason}</p>
                  </div>
                )}
                
                {post.status === "published" && (
                  <div className="pt-4 border-t border-white/5 flex items-center gap-6">
                    <div className="flex flex-col">
                      <span className="text-[10px] font-bold text-muted-foreground uppercase">Impressions</span>
                      <span className="text-sm font-bold text-white">0</span>
                    </div>
                    <div className="flex flex-col">
                      <span className="text-[10px] font-bold text-muted-foreground uppercase">Engagements</span>
                      <span className="text-sm font-bold text-white">0</span>
                    </div>
                  </div>
                )}

                {!isAdmin && (post.status === "draft" || post.status === "rejected") && (
                  <div className="pt-4 mt-2 border-t border-white/5 flex gap-2">
                    <LinkedInCreatorClient post={post} />
                  </div>
                )}
              </div>
            )) : (
              <div className="glass rounded-3xl p-12 text-center space-y-4">
                <Linkedin className="w-12 h-12 text-slate-800 mx-auto" />
                <p className="text-muted-foreground text-sm italic">No content found. Start by creating your first post!</p>
              </div>
            )}
          </div>
        </div>

        <div className="space-y-6">
          <h3 className="text-xl font-bold flex items-center gap-2">
            <Send className="w-5 h-5 text-primary" />
            Quick Actions
          </h3>
          <div className="glass rounded-3xl p-8 space-y-6">
            {!isAdmin && <LinkedInCreatorClient />}
            
            <button className="w-full bg-slate-800 hover:bg-slate-700 text-white py-4 rounded-2xl font-bold transition-all active:scale-95 text-sm flex items-center justify-center gap-2">
              <Linkedin className="w-4 h-4 text-[#0077B5]" />
              Connect LinkedIn Page
            </button>
            <div className="p-4 bg-primary/5 border border-primary/20 rounded-2xl">
              <p className="text-[10px] font-bold text-primary uppercase tracking-widest mb-1">Coming Soon</p>
              <p className="text-xs text-muted-foreground">
                Automated AI content suggestions based on your repository's recent commits.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
