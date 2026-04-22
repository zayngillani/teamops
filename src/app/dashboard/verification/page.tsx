import { CheckCircle2, AlertCircle, Github, FileText, BrainCircuit, ShieldCheck } from "lucide-react";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

export default async function VerificationPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  const isAdmin = user?.role === "admin";

  const verifications = await prisma.dailyReport.findMany({
    where: isAdmin ? {} : { userId: user.id },
    orderBy: { createdAt: "desc" },
    include: { user: true },
    take: 10
  });

  return (
    <div className="max-w-5xl mx-auto space-y-8">
      <div className="flex flex-col space-y-2">
        <h2 className="text-3xl font-bold font-display">Commit Verification</h2>
        <p className="text-muted-foreground">AI-powered comparison between daily reports and GitHub activity.</p>
      </div>

      <div className="grid grid-cols-1 gap-8">
        {verifications.length > 0 ? verifications.map((v: any) => (
          <div key={v.id} className="glass rounded-3xl overflow-hidden border border-border hover:border-primary/50 transition-all">
            <div className="p-8 space-y-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center text-primary font-bold">
                    {v.user.name?.[0] || "U"}
                  </div>
                  <div>
                    <h4 className="font-bold text-lg">{v.user.name}</h4>
                    <p className="text-sm text-muted-foreground">{new Date(v.createdAt).toLocaleDateString()}</p>
                  </div>
                </div>
                <div className="text-right">
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`text-2xl font-bold font-display ${v.verificationScore && v.verificationScore >= 90 ? "text-green-500" : "text-orange-500"}`}>
                      {v.verificationScore ? `${v.verificationScore}%` : "Pending"}
                    </span>
                    <BrainCircuit className="w-5 h-5 text-purple-500" />
                  </div>
                  <span className={`text-xs font-bold px-3 py-1 rounded-full ${v.isVerified ? "bg-green-500/10 text-green-500" : "bg-orange-500/10 text-orange-500"}`}>
                    {v.isVerified ? "VERIFIED" : "PENDING"}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div className="space-y-4">
                  <h5 className="text-sm font-bold flex items-center gap-2 text-muted-foreground">
                    <FileText className="w-4 h-4" />
                    Daily Report Claim
                  </h5>
                  <div className="p-4 bg-slate-900/50 rounded-2xl border border-white/5 italic text-sm leading-relaxed">
                    "{v.content}"
                  </div>
                </div>

                <div className="space-y-4">
                  <h5 className="text-sm font-bold flex items-center gap-2 text-muted-foreground">
                    <Github className="w-4 h-4" />
                    Actual GitHub Activity
                  </h5>
                  <div className="space-y-2">
                    <div className="p-3 bg-accent/30 rounded-xl border border-border text-xs font-mono">
                      {v.user.githubUser ? `Fetching commits for @${v.user.githubUser}...` : "No GitHub account linked."}
                    </div>
                  </div>
                </div>
              </div>

              {v.verificationLogs && (
                <div className="pt-6 border-t border-border flex items-start gap-4">
                  <ShieldCheck className="w-5 h-5 text-purple-500 shrink-0 mt-0.5" />
                  <div className="space-y-1">
                    <p className="text-sm font-bold">Claude AI Analysis</p>
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      {v.verificationLogs}
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>
        )) : (
          <div className="glass p-12 rounded-3xl text-center border border-dashed border-border">
            <BrainCircuit className="w-12 h-12 text-muted-foreground mx-auto mb-4 opacity-50" />
            <p className="text-muted-foreground">No reports found for verification.</p>
          </div>
        )}
      </div>
    </div>
  );
}
