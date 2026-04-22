import { ToggleLeft, Shield, Users } from "lucide-react";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";
import { getAllUsersWithToggles } from "@/app/actions/user";
import { FeatureToggleSwitch } from "@/components/dashboard/feature-toggle-switch";

export default async function AdminTogglesPage() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;

  if (user?.role !== "admin") {
    redirect("/dashboard");
  }

  const allUsers = await getAllUsersWithToggles();

  return (
    <div className="max-w-7xl mx-auto space-y-8">
      <div className="flex flex-col space-y-2">
        <h2 className="text-3xl font-bold font-display">Feature Management</h2>
        <p className="text-muted-foreground">Granular control over user access to portal features.</p>
      </div>

      <div className="grid grid-cols-1 gap-8">
        {allUsers.map((u: any) => (
          <div key={u.id} className="glass rounded-[40px] p-8 space-y-8 border border-white/5">
            <div className="flex items-center justify-between border-b border-border pb-6">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-primary/20 flex items-center justify-center text-primary font-bold text-xl">
                  {u.name?.[0] || "U"}
                </div>
                <div>
                  <h3 className="text-xl font-bold text-white">{u.name}</h3>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mt-1">
                    <span className="uppercase font-bold tracking-wider">{u.role.replace("_", " ")}</span>
                    <span>•</span>
                    <span>{u.email}</span>
                  </div>
                </div>
              </div>
              {u.role === "admin" && (
                <div className="bg-orange-500/10 text-orange-500 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-2">
                  <Shield className="w-4 h-4" />
                  Admin Override Active
                </div>
              )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <FeatureToggleSwitch
                userId={u.id}
                field="githubEnabled"
                label="GitHub Integration"
                description="Allow user to connect GitHub and view commits."
                iconName="ToggleLeft"
                initialValue={u.featureToggles?.githubEnabled}
              />
              <FeatureToggleSwitch
                userId={u.id}
                field="linkedinEnabled"
                label="LinkedIn Posting"
                description="Allow drafting and scheduling LinkedIn content."
                iconName="ToggleLeft"
                initialValue={u.featureToggles?.linkedinEnabled}
              />
              <FeatureToggleSwitch
                userId={u.id}
                field="verificationEnabled"
                label="AI Verification"
                description="Enable Claude AI daily report verification."
                iconName="ToggleLeft"
                initialValue={u.featureToggles?.verificationEnabled}
              />
              <FeatureToggleSwitch
                userId={u.id}
                field="breakTrackingEnabled"
                label="Break Tracking"
                description="Allow user to track break times."
                iconName="ToggleLeft"
                initialValue={u.featureToggles?.breakTrackingEnabled}
              />
              <FeatureToggleSwitch
                userId={u.id}
                field="reportRemindersEnabled"
                label="Report Reminders"
                description="Send Slack reminders to submit reports."
                iconName="ToggleLeft"
                initialValue={u.featureToggles?.reportRemindersEnabled}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
