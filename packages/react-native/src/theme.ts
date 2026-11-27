export interface DotMindTheme {
  background: string;
  edge: string;
  well: string;
  ink: string;
  peak: string;
  fontFamily: string;
  fontSize: number;
  shimmerSeconds: number;
}

export const DEFAULT_THEME: DotMindTheme = {
  background: "#0b0b0c",
  edge: "#26262a",
  well: "#050506",
  ink: "#8a8a92",
  peak: "#ffffff",
  fontFamily: "System",
  fontSize: 15,
  shimmerSeconds: 2.4,
};

export function resolveTheme(theme: Partial<DotMindTheme> | undefined): DotMindTheme {
  return theme ? { ...DEFAULT_THEME, ...theme } : DEFAULT_THEME;
}
