"use client";

import { useState, useEffect } from "react";
import { Edit2, X, Check, Shield, Globe, Users as UsersIcon, Loader2, Key, Github, Linkedin } from "lucide-react";
import { updateUser, deleteUser } from "@/app/actions/user";
import { cn } from "@/lib/utils";

interface EditUserModalProps {
  user: any;
  isOpen: boolean;
  onClose: () => void;
}

export default function EditUserModal({ user, isOpen, onClose }: EditUserModalProps) {
  const [loading, setLoading] = useState(false);
  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [newPassword, setNewPassword] = useState("");
  const [formData, setFormData] = useState({
    name: user?.name || "",
    email: user?.email || "",
    role: user?.role || "developer",
    status: user?.status || "active",
    userType: user?.userType || "DEVELOPER",
    githubUser: user?.githubUser || "",
    slackId: user?.slackId || "",
    joinDate: user?.joinDate ? new Date(user.joinDate).toISOString().split('T')[0] : "",
    canOutsideAccess: user?.canOutsideAccess || false,
    githubEnabled: user?.featureToggles?.githubEnabled || false,
    linkedinEnabled: user?.featureToggles?.linkedinEnabled || false,
    apiKeysEnabled: user?.featureToggles?.apiKeysEnabled || false,
    verificationEnabled: user?.featureToggles?.verificationEnabled || false,
  });

  // Reset form when user changes
  useEffect(() => {
    if (user) {
      setFormData({
        name: user.name || "",
        email: user.email || "",
        role: user.role || "developer",
        status: user.status || "active",
        userType: user.userType || "DEVELOPER",
        githubUser: user.githubUser || "",
        slackId: user.slackId || "",
        joinDate: user.joinDate ? new Date(user.joinDate).toISOString().split('T')[0] : "",
        canOutsideAccess: user.canOutsideAccess || false,
        githubEnabled: user.featureToggles?.githubEnabled || false,
        linkedinEnabled: user.featureToggles?.linkedinEnabled || false,
        apiKeysEnabled: user.featureToggles?.apiKeysEnabled || false,
        verificationEnabled: user.featureToggles?.verificationEnabled || false,
      });
      setShowPasswordForm(false);
      setNewPassword("");
    }
  }, [user]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    const data = new FormData();
    Object.entries(formData).forEach(([key, value]) => {
      data.append(key, value.toString());
    });

    if (newPassword) {
      data.append("password", newPassword);
    }

    try {
      await updateUser(user.id, data);
      onClose();
    } catch (error: any) {
      alert(error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-md" onClick={onClose} />
          <div className="glass relative w-full max-w-lg rounded-[40px] p-8 shadow-2xl border border-white/10 max-h-[90vh] overflow-y-auto custom-scrollbar">
            <div className="flex items-center justify-between mb-8">
              <div>
                <h3 className="text-2xl font-bold text-white">Edit Profile</h3>
                <p className="text-xs text-muted-foreground">Updating {user?.name}'s account settings.</p>
              </div>
              <button onClick={onClose} className="p-2 hover:bg-white/10 rounded-full transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6 pb-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Name</label>
                  <input 
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Email</label>
                  <input 
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Role</label>
                  <select 
                    value={formData.role}
                    onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                    className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all"
                  >
                    <option value="developer">Developer</option>
              <option value="content_creator">Content Creator</option>
              <option value="outreach_specialist">Outreach Specialist</option>
              <option value="devops">DevOps</option>
              <option value="admin">Admin</option>
                  </select>
                </div>
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Status</label>
                  <select 
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                    className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all"
                  >
                    <option value="active">Active</option>
                    <option value="pending">Pending</option>
                    <option value="suspended">Suspended</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Joining Date</label>
                  <input 
                    type="date"
                    value={formData.joinDate}
                    onChange={(e) => setFormData({ ...formData, joinDate: e.target.value })}
                    className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest ml-1">Slack ID</label>
                  <input 
                    value={formData.slackId}
                    onChange={(e) => setFormData({ ...formData, slackId: e.target.value })}
                    className="w-full bg-slate-900/50 border border-white/5 rounded-2xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/50 transition-all" 
                  />
                </div>
              </div>

              <div className="space-y-4 pt-4 border-t border-white/5">
                <button 
                  type="button"
                  onClick={() => setShowPasswordForm(!showPasswordForm)}
                  className="w-full flex items-center justify-between p-4 bg-slate-900/50 border border-white/5 rounded-2xl hover:bg-slate-800/50 transition-all"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-orange-500/10 flex items-center justify-center text-orange-500">
                      <Key className="w-5 h-5" />
                    </div>
                    <div className="text-left">
                      <p className="text-sm font-bold text-white">Reset Password</p>
                      <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Update team member credentials</p>
                    </div>
                  </div>
                </button>

                {showPasswordForm && (
                  <div className="space-y-1 animate-in slide-in-from-top-2 duration-300">
                    <label className="text-[10px] font-bold text-orange-500 uppercase tracking-widest ml-1">New Password</label>
                    <input 
                      type="password"
                      placeholder="Enter new secure password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      className="w-full bg-slate-900/50 border border-orange-500/20 rounded-2xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-orange-500/50 transition-all" 
                    />
                  </div>
                )}

                <div className="flex items-center justify-between p-4 bg-slate-900/50 border border-white/5 rounded-2xl">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
                      <Globe className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-white">Outside IP Access</p>
                      <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Bypass IP Whitelist</p>
                    </div>
                  </div>
                  <input 
                    type="checkbox"
                    checked={formData.canOutsideAccess}
                    onChange={(e) => setFormData({ ...formData, canOutsideAccess: e.target.checked })}
                    className="w-5 h-5 accent-primary"
                  />
                </div>

                <div className="flex items-center justify-between p-4 bg-slate-900/50 border border-white/5 rounded-2xl">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-[#24292e]/20 flex items-center justify-center text-white">
                      <Github className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-white">GitHub Access</p>
                      <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Enable GitHub Integration</p>
                    </div>
                  </div>
                  <input 
                    type="checkbox"
                    checked={formData.githubEnabled}
                    onChange={(e) => setFormData({ ...formData, githubEnabled: e.target.checked })}
                    className="w-5 h-5 accent-primary"
                  />
                </div>

                <div className="flex items-center justify-between p-4 bg-slate-900/50 border border-white/5 rounded-2xl">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-[#0077B5]/20 flex items-center justify-center text-[#0077B5]">
                      <Linkedin className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-white">LinkedIn Access</p>
                      <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Enable LinkedIn Posting</p>
                    </div>
                  </div>
                  <input 
                    type="checkbox"
                    checked={formData.linkedinEnabled}
                    onChange={(e) => setFormData({ ...formData, linkedinEnabled: e.target.checked })}
                    className="w-5 h-5 accent-primary"
                  />
                </div>

                <div className="flex items-center justify-between p-4 bg-slate-900/50 border border-white/5 rounded-2xl">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-purple-500/10 flex items-center justify-center text-purple-500">
                      <Key className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-white">API Keys Access</p>
                      <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Enable Claude API Key Access</p>
                    </div>
                  </div>
                  <input 
                    type="checkbox"
                    checked={formData.apiKeysEnabled}
                    onChange={(e) => setFormData({ ...formData, apiKeysEnabled: e.target.checked })}
                    className="w-5 h-5 accent-primary"
                  />
                </div>

                <div className="flex items-center justify-between p-4 bg-slate-900/50 border border-white/5 rounded-2xl">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-green-500/10 flex items-center justify-center text-green-500">
                      <Shield className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-white">Commit Verification</p>
                      <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Enable Daily Push Verification</p>
                    </div>
                  </div>
                  <input 
                    type="checkbox"
                    checked={formData.verificationEnabled}
                    onChange={(e) => setFormData({ ...formData, verificationEnabled: e.target.checked })}
                    className="w-5 h-5 accent-primary"
                  />
                </div>
              </div>

              <div className="flex gap-4 mt-8">
                <button 
                  type="button"
                  onClick={async () => {
                    if (confirm("Are you sure you want to delete this user? This cannot be undone.")) {
                      setLoading(true);
                      await deleteUser(user.id);
                      onClose();
                      setLoading(false);
                    }
                  }}
                  className="flex-1 bg-slate-900 hover:bg-red-500/10 text-muted-foreground hover:text-red-500 py-4 rounded-2xl font-bold transition-all border border-white/5 active:scale-95"
                >
                  Delete Account
                </button>
                <button 
                  type="submit" 
                  disabled={loading}
                  className="flex-[2] bg-primary hover:bg-primary-hover text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-50"
                >
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : "Save Changes"}
                </button>
              </div>
            </form>
          </div>
        </div>
    );
}
