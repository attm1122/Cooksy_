import { router } from "expo-router";
import { AlertCircle, Flag, ShieldCheck, XCircle } from "lucide-react-native";
import { useEffect, useState } from "react";
import { Alert, RefreshControl, ScrollView, Text, View } from "react-native";

import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { EmptyState } from "@/components/common/EmptyState";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { captureError } from "@/lib/monitoring";
import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/store/use-auth-store";

type ContentReport = {
  id: string;
  recipe_id: string;
  reason: string;
  details?: string;
  status: "pending" | "reviewing" | "resolved" | "dismissed";
  created_at: string;
  recipe?: {
    title: string;
    source_url: string;
    source_creator: string;
  };
};

type ModerationStats = {
  pending_reports: number;
  flagged_content: number;
  blocked_today: number;
  total_reports: number;
};

export default function AdminModerationScreen() {
  const [reports, setReports] = useState<ContentReport[]>([]);
  const [stats, setStats] = useState<ModerationStats | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [updating, setUpdating] = useState<string | null>(null);
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);
  const userId = useAuthStore((state) => state.userId);

  // Guard: verify admin role via Supabase JWT claims before rendering any data
  useEffect(() => {
    if (!userId) {
      router.replace("/home" as never);
      return;
    }

    if (!supabase) {
      setIsAdmin(false);
      return;
    }

    supabase.auth.getUser().then(({ data, error }) => {
      if (error || !data.user) {
        router.replace("/home" as never);
        return;
      }
      const role = data.user.app_metadata?.role as string | undefined;
      if (role !== "admin") {
        router.replace("/home" as never);
        return;
      }
      setIsAdmin(true);
    });
  }, [userId]);

  const fetchModerationData = async () => {
    try {
      if (!supabase) {
        Alert.alert("Error", "Supabase not configured");
        return;
      }

      // Fetch stats
      const { data: statsData, error: statsError } = await supabase
        .rpc("get_moderation_stats");
      
      if (statsError) throw statsError;
      
      if (statsData && statsData.length > 0) {
        setStats(statsData[0] as ModerationStats);
      }

      // Fetch pending reports
      const { data: reportsData, error: reportsError } = await supabase
        .from("content_reports")
        .select(`
          id,
          recipe_id,
          reason,
          details,
          status,
          created_at,
          recipes:recipe_id (
            title,
            source_url,
            source_creator
          )
        `)
        .in("status", ["pending", "reviewing"])
        .order("created_at", { ascending: false });

      if (reportsError) throw reportsError;

      // Transform the data
      const transformedReports: ContentReport[] = (reportsData || []).map((r: any) => ({
        id: r.id,
        recipe_id: r.recipe_id,
        reason: r.reason,
        details: r.details,
        status: r.status,
        created_at: r.created_at,
        recipe: r.recipes ? {
          title: r.recipes.title,
          source_url: r.recipes.source_url,
          source_creator: r.recipes.source_creator
        } : undefined
      }));

      setReports(transformedReports);
    } catch (error) {
      captureError(error, { action: "fetch_moderation_data" });
      Alert.alert("Error", "Failed to load moderation data");
    } finally {
      setRefreshing(false);
    }
  };

  useEffect(() => {
    void fetchModerationData();
  }, []);

  const handleUpdateStatus = async (reportId: string, status: "resolved" | "dismissed") => {
    if (!supabase) return;
    
    setUpdating(reportId);
    try {
      const { error } = await supabase
        .from("content_reports")
        .update({
          status,
          resolved_at: new Date().toISOString(),
          resolved_by: (await supabase.auth.getUser()).data.user?.id
        })
        .eq("id", reportId);

      if (error) throw error;

      // Refresh data
      await fetchModerationData();
    } catch (error) {
      captureError(error, { action: "update_report_status", reportId, status });
      Alert.alert("Error", "Failed to update report status");
    } finally {
      setUpdating(null);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    void fetchModerationData();
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit"
    });
  };

  // Block render until admin check resolves
  if (isAdmin !== true) {
    return null;
  }

  return (
    <ScreenContainer scroll={false}>
      <Text className="mb-2 text-[28px] font-bold text-ink">Moderation Dashboard</Text>
      <Text className="mb-5 text-[15px] text-muted">
        Review reported content and manage community guidelines.
      </Text>

      {stats && (
        <View className="mb-5 flex-row flex-wrap" style={{ gap: 12 }}>
          <StatCard
            icon={Flag}
            value={stats.pending_reports}
            label="Pending"
            color="#F5C400"
          />
          <StatCard
            icon={AlertCircle}
            value={stats.flagged_content}
            label="Under Review"
            color="#F97316"
          />
          <StatCard
            icon={XCircle}
            value={stats.blocked_today}
            label="Blocked Today"
            color="#EF4444"
          />
          <StatCard
            icon={ShieldCheck}
            value={stats.total_reports}
            label="Total Reports"
            color="#22C55E"
          />
        </View>
      )}

      <ScrollView
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        contentContainerClassName="pb-10"
      >
        <Text className="mb-3 text-[20px] font-bold text-ink">Pending Reports</Text>
        
        {reports.length === 0 ? (
          <EmptyState
            title="No pending reports"
            description="All caught up! There are no content reports requiring review."
          />
        ) : (
          <View style={{ gap: 12 }}>
            {reports.map((report) => (
              <CooksyCard key={report.id} className="p-4">
                <View style={{ gap: 12 }}>
                  <View className="flex-row items-start justify-between">
                    <View className="flex-1">
                      <Text className="text-[13px] font-bold uppercase tracking-[0.8px] text-muted">
                        {report.reason}
                      </Text>
                      <Text className="mt-1 text-[18px] font-bold text-ink">
                        {report.recipe?.title || "Unknown Recipe"}
                      </Text>
                      <Text className="mt-1 text-[14px] text-muted">
                        From: {report.recipe?.source_creator || "Unknown"}
                      </Text>
                    </View>
                    <StatusBadge status={report.status} />
                  </View>

                  {report.details && (
                    <View className="rounded-[16px] bg-surface-alt px-4 py-3">
                      <Text className="text-[14px] text-soft-ink">{report.details}</Text>
                    </View>
                  )}

                  <View className="flex-row items-center justify-between">
                    <Text className="text-[13px] text-muted">
                      Reported {formatDate(report.created_at)}
                    </Text>
                    <View className="flex-row" style={{ gap: 8 }}>
                      <SecondaryButton
                        fullWidth={false}
                        onPress={() => handleUpdateStatus(report.id, "dismissed")}
                        disabled={updating === report.id}
                      >
                        Dismiss
                      </SecondaryButton>
                      <PrimaryButton
                        fullWidth={false}
                        onPress={() => handleUpdateStatus(report.id, "resolved")}
                        loading={updating === report.id}
                      >
                        Resolve
                      </PrimaryButton>
                    </View>
                  </View>

                  {report.recipe && (
                    <SecondaryButton
                      onPress={() => router.push(`/recipe/${report.recipe_id}`)}
                      fullWidth={false}
                    >
                      View Recipe
                    </SecondaryButton>
                  )}
                </View>
              </CooksyCard>
            ))}
          </View>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}

function StatCard({
  icon: Icon,
  value,
  label,
  color
}: {
  icon: typeof Flag;
  value: number;
  label: string;
  color: string;
}) {
  return (
    <View className="min-w-[100px] flex-1 rounded-[20px] border border-line bg-surface p-4">
      <View className="mb-2 h-10 w-10 items-center justify-center rounded-full" style={{ backgroundColor: `${color}20` }}>
        <Icon size={20} color={color} />
      </View>
      <Text className="text-[28px] font-bold text-ink">{value}</Text>
      <Text className="text-[13px] text-muted">{label}</Text>
    </View>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    pending: "#F5C400",
    reviewing: "#F97316",
    resolved: "#22C55E",
    dismissed: "#6B7280"
  };

  const labels: Record<string, string> = {
    pending: "Pending",
    reviewing: "Reviewing",
    resolved: "Resolved",
    dismissed: "Dismissed"
  };

  const color = colors[status] || "#6B7280";

  return (
    <View
      className="rounded-full px-3 py-1"
      style={{ backgroundColor: `${color}20` }}
    >
      <Text className="text-[12px] font-semibold" style={{ color }}>
        {labels[status] || status}
      </Text>
    </View>
  );
}
