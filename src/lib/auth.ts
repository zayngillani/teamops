import { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import { PrismaAdapter } from "@auth/prisma-adapter";
import prisma from "./prisma";
import bcrypt from "bcryptjs";

function defaultToggles(role: string) {
  return {
    githubEnabled: role === "developer" || role === "devops" || role === "admin",
    linkedinEnabled: role === "content_creator" || role === "admin",
    verificationEnabled: role === "developer" || role === "admin",
    breakTrackingEnabled: true,
    reportRemindersEnabled: true,
  };
}

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma) as any,
  providers: [
    CredentialsProvider({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          throw new Error("Missing credentials");
        }

        const user = await prisma.user.findUnique({
          where: { email: credentials.email },
          include: { featureToggles: true },
        });

        if (!user || !user.password) {
          throw new Error("Invalid credentials");
        }

        if (user.status === "suspended") {
          throw new Error("Account suspended. Contact admin.");
        }

        const isPasswordCorrect = await bcrypt.compare(
          credentials.password,
          user.password
        );

        if (!isPasswordCorrect) {
          throw new Error("Invalid credentials");
        }

        // Auto-create feature toggles on first login if missing
        if (!user.featureToggles) {
          await prisma.userFeatureToggle.create({
            data: { userId: user.id, ...defaultToggles(user.role) },
          });
        }

        return {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          status: user.status,
          canOutsideAccess: user.canOutsideAccess,
        };
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.role = (user as any).role;
        token.id = user.id;
        token.status = (user as any).status;
        token.canOutsideAccess = (user as any).canOutsideAccess;
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        (session.user as any).role = token.role as any;
        (session.user as any).id = token.id as string;
        (session.user as any).status = token.status as string;
        (session.user as any).canOutsideAccess = token.canOutsideAccess as boolean;
      }
      return session;
    },
  },
  session: {
    strategy: "jwt",
  },
  pages: {
    signIn: "/login",
  },
  secret: process.env.NEXTAUTH_SECRET,
};
