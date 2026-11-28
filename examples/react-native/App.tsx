import { useEffect, useState, type ReactNode } from "react";
import { Platform, ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { classifyTool, DotMind, labelFor, useActivityTracker, type Activity, type SceneName } from "dotmind-native";
import { playAgentTurn } from "./agentTurn";

const SCRIPTED: readonly Activity[] = [
  { phase: "thinking" },
  { phase: "tool", tool: "web_search" },
  { phase: "tool", tool: "web_fetch" },
  { phase: "tool", tool: "bash" },
  { phase: "tool", tool: "read_file" },
  { phase: "tool", tool: "run_sql" },
  { phase: "tool", tool: "calculate_margin" },
  { phase: "tool", tool: "get_weather" },
  { phase: "writing" },
  { phase: "waiting", tool: "deploy_config" },
  { phase: "error" },
  { phase: "done" },
];

const STATES = SCRIPTED.map((activity) => (activity.tool ? { ...activity, kind: classifyTool(activity.tool) } : activity));

const SCENES: readonly SceneName[] = ["ember", "orbit", "prism", "serpent", "circuit", "pulse", "comet", "halo"];

const HERO_THEME = { fontSize: 24 };

function describe(activity: Activity): string {
  return activity.tool ? `phase="${activity.phase}" tool="${activity.tool}"` : `phase="${activity.phase}"`;
}

function LiveTurn() {
  const tracker = useActivityTracker();
  const [shown, setShown] = useState<string[]>([]);

  useEffect(() => {
    const unsubscribe = tracker.subscribe((activity) => {
      if (activity.phase === "idle") return setShown([]);
      const label = labelFor(activity);
      setShown((list) => (list[list.length - 1] === label ? list : [...list, label]));
    });
    const stop = playAgentTurn(tracker);
    return () => {
      stop();
      unsubscribe();
    };
  }, [tracker]);

  return (
    <View style={styles.stage}>
      <DotMind tracker={tracker} size={56} theme={HERO_THEME} />
      <View style={styles.panel}>
        <Text style={styles.eyebrow}>What the dots showed</Text>
        <View style={styles.track}>
          {shown.map((label, index) => (
            <Text key={index} style={[styles.chip, index === shown.length - 1 && styles.chipOn]}>
              {label}
            </Text>
          ))}
        </View>
      </View>
    </View>
  );
}

function Cell({ caption, children }: { caption: string; children: ReactNode }) {
  return (
    <View style={styles.cell}>
      {children}
      <Text style={styles.caption} numberOfLines={1}>
        {caption}
      </Text>
    </View>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <SafeAreaView style={styles.screen} edges={["top", "left", "right"]}>
        <ScrollView contentContainerStyle={styles.content}>
          <View style={styles.header}>
            <Text style={styles.eyebrow}>dotmind · react native</Text>
            <Text style={styles.title}>The dots know what the model is doing</Text>
            <Text style={styles.body}>
              A scripted agent turn drives the tracker: it thinks, searches the web, runs code, writes the answer and
              finishes.
            </Text>
          </View>

          <LiveTurn />

          <View style={styles.section}>
            <Text style={styles.heading}>Every state</Text>
            {STATES.map((activity) => (
              <Cell key={describe(activity)} caption={describe(activity)}>
                <DotMind activity={activity} size={34} />
              </Cell>
            ))}
          </View>

          <View style={styles.section}>
            <Text style={styles.heading}>The original eight</Text>
            {SCENES.map((scene) => (
              <Cell key={scene} caption={`scene="${scene}"`}>
                <DotMind scene={scene} label="Thinking" size={34} />
              </Cell>
            ))}
          </View>
        </ScrollView>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const mono = Platform.select({ ios: "Menlo", default: "monospace" });

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#121213" },
  content: { paddingHorizontal: 20, paddingTop: 24, paddingBottom: 56, gap: 44 },
  header: { gap: 12 },
  eyebrow: { fontFamily: mono, fontSize: 11, letterSpacing: 2, textTransform: "uppercase", color: "#55555c" },
  title: { fontSize: 32, lineHeight: 36, fontWeight: "600", letterSpacing: -0.8, color: "#ececef" },
  body: { fontSize: 15, lineHeight: 23, color: "#8a8a92" },
  stage: {
    gap: 22,
    padding: 22,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "#232327",
    backgroundColor: "#0d0d0e",
  },
  panel: { gap: 10 },
  track: { flexDirection: "row", flexWrap: "wrap", gap: 6, minHeight: 25 },
  chip: {
    fontFamily: mono,
    fontSize: 11,
    letterSpacing: 0.6,
    textTransform: "uppercase",
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 999,
    overflow: "hidden",
    backgroundColor: "#1a1a1d",
    color: "#8a8a92",
  },
  chipOn: { backgroundColor: "#26263a", color: "#ececef" },
  section: { gap: 18 },
  heading: { fontSize: 20, fontWeight: "600", letterSpacing: -0.2, color: "#ececef" },
  cell: { gap: 8 },
  caption: { fontFamily: mono, fontSize: 11, color: "#55555c", paddingHorizontal: 14 },
});
