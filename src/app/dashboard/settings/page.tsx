import { Settings, Shield, Bell, Database, Plus, Trash2, Globe, Github, Linkedin, CheckCircle2, Coffee, Clock } from "lucide-react";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { getUserToggles } from "@/lib/toggles";
import { FeatureToggleSwitch } from "@/components/dashboard/feature-toggle-switch";
import { redirect } from "next/navigation";

export default async function SettingsPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;

  const isAdmin = user?.role === "admin";
  if (!isAdmin) {
    redirect("/dashboard");
  }

  const whitelistedIPs = isAdmin
    ? await prisma.ipManagement.findMany({ orderBy: { createdAt: "desc" } })
    : [];

  const toggles = await getUserToggles(user.id);

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <div className="flex flex-col space-y-2">
        <h2 className="text-3xl font-bold font-display">System Settings</h2>
        <p className="text-muted-foreground">Configure global security and automation protocols.</p>
      </div>

      {isAdmin && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="md:col-span-2 space-y-8">
            {/* IP Whitelist Management */}
            <div className="glass rounded-[40px] p-8 space-y-6">
              <div className="flex items-center justify-between">
                <h3 className="text-xl font-bold flex items-center gap-2">
                  <Shield className="w-5 h-5 text-primary" />
                  IP Whitelist
                </h3>
                <button className="bg-primary/10 hover:bg-primary/20 text-primary px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition-all">
                  <Plus className="w-4 h-4" />
                  Add IP
                </button>
              </div>

              <div className="space-y-3">
                {whitelistedIPs.map((ip: any) => (
                  <div
                    key={ip.id}
                    className="flex items-center justify-between p-4 bg-slate-900/50 border border-white/5 rounded-2xl"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-2 h-2 rounded-full bg-green-500" />
                      <div>
                        <p className="text-sm font-mono text-white">{ip.ipAddress}</p>
                        <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">
                          {ip.description || "Authorized Location"}
                        </p>
                      </div>
                    </div>
                    <button className="p-2 hover:bg-destructive/10 text-muted-foreground hover:text-destructive rounded-lg transition-all">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Automation Config */}
            <div className="glass rounded-[40px] p-8 space-y-6">
              <h3 className="text-xl font-bold flex items-center gap-2">
                <Bell className="w-5 h-5 text-primary" />
                Notifications
              </h3>
              <div className="space-y-4">
                <div className="flex items-center justify-between p-6 bg-slate-900/50 border border-white/5 rounded-2xl">
                  <div>
                    <p className="text-sm font-bold text-white">Slack Check-in Alerts</p>
                    <p className="text-xs text-muted-foreground">
                      Notify the #reports channel on every check-in.
                    </p>
                  </div>
                  <div className="w-12 h-6 bg-primary rounded-full relative">
                    <div className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full shadow-sm" />
                  </div>
                </div>
                <div className="flex items-center justify-between p-6 bg-slate-900/50 border border-white/5 rounded-2xl">
                  <div>
                    <p className="text-sm font-bold text-white">Auto-Checkout</p>
                    <p className="text-xs text-muted-foreground">
                      Automatically close sessions after 24 hours.
                    </p>
                  </div>
                  <div className="w-12 h-6 bg-primary rounded-full relative">
                    <div className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full shadow-sm" />
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Info Sidebar */}
          <div className="space-y-6">
            <div className="glass rounded-3xl p-6 bg-primary/5 border-primary/20 space-y-4">
              <h4 className="font-bold flex items-center gap-2 text-sm">
                <Database className="w-4 h-4 text-primary" />
                Database Health
              </h4>
              <div className="space-y-2">
                <div className="flex justify-between text-xs">
                  <span className="text-muted-foreground">Status</span>
                  <span className="text-green-500 font-bold">Optimal</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-muted-foreground">Latency</span>
                  <span className="text-white">12ms</span>
                </div>
              </div>
            </div>

            <div className="glass rounded-3xl p-6 space-y-4 border-white/5">
              <h4 className="font-bold text-sm">Deployment</h4>
              <div className="flex items-center gap-2 text-[10px] font-mono text-muted-foreground">
                <Globe className="w-3 h-3" />
                prod-v1.2.0-stable
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
