import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { getUserToggles } from "@/lib/toggles";
import { SidebarNav } from "./sidebar-nav";

export async function Sidebar() {
  const session = await getServerSession(authOptions);
  const user = session?.user as any;
  const toggles = await getUserToggles(user?.id);

  const items = [
    ...(user?.role === "admin" ? [{ title: "Dashboard", href: "/dashboard", icon: "LayoutDashboard" }] : []),
    { title: "Attendance", href: "/dashboard/attendance", icon: "Clock", always: true },
    { title: "Daily Reports", href: "/dashboard/reports", icon: "FileText", always: true },
    { title: "Leave Requests", href: "/dashboard/leaves", icon: "Calendar", always: true },
    ...(toggles?.githubEnabled ? [{ title: "GitHub", href: "/dashboard/github", icon: "Github" }] : []),
    ...(toggles?.linkedinEnabled ? [{ title: "LinkedIn", href: "/dashboard/linkedin", icon: "Linkedin" }] : []),
    ...(toggles?.verificationEnabled ? [{ title: "Verification", href: "/dashboard/verification", icon: "CheckCircle2" }] : []),
    ...((toggles as any)?.apiKeysEnabled ? [{ title: "API Keys", href: "/dashboard/keys", icon: "Key" }] : []),
    ...(user?.role === "admin"
      ? [
          { title: "Users", href: "/dashboard/users", icon: "Users" },
          { title: "Recruitment", href: "/dashboard/recruitment", icon: "Briefcase" },
          { title: "LinkedIn Approvals", href: "/dashboard/admin/linkedin", icon: "ThumbsUp" },
          { title: "Settings", href: "/dashboard/settings", icon: "Settings" },
        ]
      : []),
  ];

  return <SidebarNav items={items} user={user} />;
}
