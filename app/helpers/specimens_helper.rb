module SpecimensHelper
  TINT_STYLES = {
    "slate"    => { bg: "from-slate-200 to-slate-400",    badge: "bg-slate-100 text-slate-800 ring-slate-300",       fill: "#e2e8f0", line: "#475569" },
    "rose"     => { bg: "from-rose-200 to-rose-500",      badge: "bg-rose-100 text-rose-800 ring-rose-300",          fill: "#fda4af", line: "#9f1239" },
    "blue"     => { bg: "from-blue-200 to-blue-600",      badge: "bg-blue-100 text-blue-800 ring-blue-300",          fill: "#93c5fd", line: "#1e3a8a" },
    "emerald"  => { bg: "from-emerald-200 to-emerald-600", badge: "bg-emerald-100 text-emerald-800 ring-emerald-300", fill: "#6ee7b7", line: "#065f46" },
    "fuchsia"  => { bg: "from-fuchsia-200 to-fuchsia-500", badge: "bg-fuchsia-100 text-fuchsia-800 ring-fuchsia-300", fill: "#f0abfc", line: "#86198f" },
    "purple"   => { bg: "from-purple-200 to-purple-600",  badge: "bg-purple-100 text-purple-800 ring-purple-300",    fill: "#d8b4fe", line: "#581c87" },
    "sky"      => { bg: "from-sky-200 to-sky-500",        badge: "bg-sky-100 text-sky-800 ring-sky-300",             fill: "#7dd3fc", line: "#075985" },
    "cyan"     => { bg: "from-cyan-200 to-cyan-500",      badge: "bg-cyan-100 text-cyan-800 ring-cyan-300",          fill: "#67e8f9", line: "#155e75" },
    "indigo"   => { bg: "from-indigo-200 to-indigo-600",  badge: "bg-indigo-100 text-indigo-800 ring-indigo-300",    fill: "#a5b4fc", line: "#312e81" },
    "red"      => { bg: "from-red-200 to-red-600",        badge: "bg-red-100 text-red-800 ring-red-300",             fill: "#fca5a5", line: "#7f1d1d" },
    "pink"     => { bg: "from-pink-200 to-pink-500",      badge: "bg-pink-100 text-pink-800 ring-pink-300",          fill: "#f9a8d4", line: "#9d174d" },
    "teal"     => { bg: "from-teal-200 to-teal-500",      badge: "bg-teal-100 text-teal-800 ring-teal-300",          fill: "#5eead4", line: "#115e59" }
  }.freeze

  def specimen_tint_style(tint)
    TINT_STYLES[tint] || TINT_STYLES["slate"]
  end

  def specimen_tints_json
    TINT_STYLES.transform_values { |v| v.merge(badge: v[:badge] + " ring-1") }.to_json
  end
end
