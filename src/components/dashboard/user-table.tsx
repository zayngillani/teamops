"use client";

import { useState } from "react";
import { Edit2, Clock } from "lucide-react";
import { cn } from "@/lib/utils";
import EditUserModal from "@/components/EditUserModal";
import Link from "next/link";

interface UserTableProps {
  users: any[];
}

export function UserTable({ users }: UserTableProps) {
  const [selectedUser, setSelectedUser] = useState<any>(null);

  return (
    <>
      <div className="glass rounded-3xl overflow-hidden">
        <table className="w-full text-left">
          <thead>
            <tr className="text-xs font-bold text-muted-foreground uppercase tracking-wider border-b border-border bg-accent/20">
              <th className="px-8 py-5">User</th>
              <th className="px-8 py-5">Role</th>
              <th className="px-8 py-5">GitHub</th>
              <th className="px-8 py-5">Joined</th>
              <th className="px-8 py-5">Status</th>
              <th className="px-8 py-5"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {users.map((user: any) => (
              <tr key={user.id} className="hover:bg-accent/30 transition-colors">
                <td className="px-8 py-6">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold">
                      {user.name?.[0] || user.email?.[0]}
                    </div>
                    <div>
                      <p className="text-sm font-bold">{user.name}</p>
                      <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-wider">{user.userType || "DEVELOPER"}</p>
                    </div>
                  </div>
                </td>
                <td className="px-8 py-6">
                  <span className={cn(
                    "text-[10px] font-bold px-3 py-1 rounded-full uppercase",
                    user.role === "admin" ? "bg-primary/10 text-primary border border-primary/20" : "bg-slate-800 text-muted-foreground"
                  )}>
                    {user.role}
                  </span>
                </td>
                <td className="px-8 py-6 text-sm text-muted-foreground">
                  <div className="flex flex-col">
                    <span className="text-white">{user.githubUser || "—"}</span>
                    <span className="text-[10px] text-muted-foreground">{user.slackId || ""}</span>
                  </div>
                </td>
                <td className="px-8 py-6 text-sm text-muted-foreground">
                  {user.joinDate ? new Date(user.joinDate).toLocaleDateString() : "—"}
                </td>
                <td className="px-8 py-6">
                  <div className="flex items-center gap-2">
                    <div className={cn(
                      "w-2 h-2 rounded-full",
                      user.status === "active" ? "bg-green-500" : "bg-orange-500"
                    )} />
                    <span className={cn(
                      "text-[10px] font-bold uppercase",
                      user.status === "active" ? "text-green-500" : "text-orange-500"
                    )}>{user.status}</span>
                  </div>
                </td>
                <td className="px-8 py-6 text-right">
                  <div className="flex items-center justify-end gap-2">
                    <Link
                      href={`/dashboard/attendance?userId=${user.id}`}
                      className="p-2 hover:bg-primary/10 rounded-lg transition-colors text-muted-foreground hover:text-primary"
                      title="View Attendance"
                    >
                      <Clock className="w-4 h-4" />
                    </Link>
                    <button 
                      onClick={() => setSelectedUser(user)}
                      className="p-2 hover:bg-accent rounded-lg transition-colors text-muted-foreground hover:text-white"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal is rendered OUTSIDE the table container to avoid clipping */}
      {selectedUser && (
        <EditUserModal 
          user={selectedUser} 
          isOpen={!!selectedUser} 
          onClose={() => setSelectedUser(null)} 
        />
      )}
    </>
  );
}
