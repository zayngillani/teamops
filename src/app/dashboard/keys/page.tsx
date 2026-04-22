import { Key, Copy, RefreshCw, AlertTriangle, Clock } from "lucide-react";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { getClaudeKey } from "@/lib/claude";
import prisma from "@/lib/prisma";

export default async function KeysPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  
  const config = await prisma.systemConfig.findUnique({
    where: { id: "config" },
  });

  const key = config?.claudeToken || "No active session token";
  const expiry = config?.tokenExpiry;
  const lastRotation = config?.lastRotation;

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <div className="flex flex-col space-y-2">
        <h2 className="text-3xl font-bold font-display">API Keys</h2>
        <p className="text-muted-foreground">Access current session tokens for Claude API.</p>
      </div>

      <div className="glass rounded-3xl p-8 space-y-8">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-purple-500/10 flex items-center justify-center text-purple-500">
              <Key className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-xl font-bold">Claude Session Token</h3>
              <p className="text-sm text-muted-foreground">Rotates every 8 hours</p>
            </div>
          </div>
          {user.role === "ADMIN" && (
            <button className="flex items-center gap-2 bg-accent hover:bg-accent/80 px-4 py-2 rounded-xl text-sm font-bold transition-all active:scale-95">
              <RefreshCw className="w-4 h-4" />
              Force Rotate
            </button>
          )}
        </div>

        <div className="space-y-4">
          <div className="relative group">
            <div className="absolute inset-0 bg-gradient-to-r from-purple-500/10 to-indigo-500/10 rounded-2xl blur-xl opacity-50 group-hover:opacity-100 transition-opacity" />
            <div className="relative bg-slate-900/50 border border-border rounded-2xl p-6 flex items-center justify-between font-mono text-sm break-all">
              <span className="text-purple-400">{key}</span>
              <button className="p-2 hover:bg-accent rounded-lg transition-colors shrink-0 ml-4">
                <Copy className="w-4 h-4" />
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="glass rounded-2xl p-4 flex items-center gap-4">
              <Clock className="w-5 h-5 text-muted-foreground" />
              <div>
                <p className="text-xs text-muted-foreground uppercase font-bold tracking-wider">Expires In</p>
                <p className="font-bold text-sm">
                  {expiry ? "5h 24m" : "N/A"}
                </p>
              </div>
            </div>
            <div className="glass rounded-2xl p-4 flex items-center gap-4">
              <RefreshCw className="w-5 h-5 text-muted-foreground" />
              <div>
                <p className="text-xs text-muted-foreground uppercase font-bold tracking-wider">Last Rotation</p>
                <p className="font-bold text-sm">
                  {lastRotation ? lastRotation.toLocaleTimeString() : "N/A"}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-orange-500/5 border border-orange-500/20 rounded-2xl p-6 flex gap-4 items-start">
          <AlertTriangle className="w-6 h-6 text-orange-500 shrink-0" />
          <div className="space-y-2">
            <p className="text-sm font-bold text-orange-500">Important Security Notice</p>
            <p className="text-sm text-muted-foreground leading-relaxed">
              This token is for your personal use in development. Never commit this token to version control or share it via insecure channels. The token will expire automatically.
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div className="glass rounded-3xl p-8 space-y-4">
          <h4 className="font-bold">Usage Policy</h4>
          <ul className="text-sm text-muted-foreground space-y-3">
            <li className="flex gap-2">
              <span className="text-primary font-bold">•</span>
              Used for Daily Report verification logic.
            </li>
            <li className="flex gap-2">
              <span className="text-primary font-bold">•</span>
              Max 50 calls per session per developer.
            </li>
            <li className="flex gap-2">
              <span className="text-primary font-bold">•</span>
              Usage is logged and monitored for cost tracking.
            </li>
          </ul>
        </div>

        <div className="glass rounded-3xl p-8 space-y-4">
          <h4 className="font-bold">Rotation Schedule</h4>
          <div className="space-y-3">
            <div className="flex justify-between items-center text-sm">
              <span className="text-muted-foreground">Next Rotation</span>
              <span className="font-bold">12:00 AM</span>
            </div>
            <div className="flex justify-between items-center text-sm">
              <span className="text-muted-foreground">Frequency</span>
              <span className="font-bold">Every 8 Hours</span>
            </div>
            <div className="flex justify-between items-center text-sm">
              <span className="text-muted-foreground">Reminder</span>
              <span className="text-primary font-bold">30m before expiry</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
