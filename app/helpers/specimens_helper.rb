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

  # Server-rendered gem facet SVG (ported from the old client-side renderer so
  # the collection works without JavaScript).
  def specimen_gem_svg(tint, size_class = "w-20 h-20 sm:w-24 sm:h-24")
    s = specimen_tint_style(tint)
    tag.svg(viewBox: "0 0 64 64", class: "#{size_class} drop-shadow", "aria-hidden": true) do
      safe_join([
        tag.polygon(points: "32,6 56,26 32,58 8,26", fill: s[:fill], stroke: s[:line], "stroke-width": "1.2"),
        tag.polyline(points: "8,26 32,34 56,26", fill: "none", stroke: s[:line], "stroke-width": "1"),
        tag.line(x1: "20", y1: "14", x2: "32", y2: "34", stroke: s[:line], "stroke-width": "0.8", opacity: "0.7"),
        tag.line(x1: "44", y1: "14", x2: "32", y2: "34", stroke: s[:line], "stroke-width": "0.8", opacity: "0.7"),
        tag.polygon(points: "20,14 32,6 44,14 32,26", fill: "white", opacity: "0.3")
      ])
    end
  end

  # Mohs hardness meter (1-10). Returns nil when no value is recorded.
  def specimen_mohs_meter(mohs)
    return if mohs.blank?

    pct = [[mohs.to_f / 10 * 100, 0].max, 100].min
    tag.div(class: "mt-3") do
      safe_join([
        tag.div(class: "flex justify-between text-[10px] font-semibold uppercase tracking-wider text-slate-500") do
          safe_join([tag.span("Mohs hardness"), tag.span("#{mohs} / 10")])
        end,
        tag.div(class: "mt-1 h-2 rounded-full bg-stone-200 overflow-hidden") do
          tag.div(class: "h-full rounded-full bg-gradient-to-r from-stone-400 via-amber-400 to-amber-600", style: "width:#{pct}%")
        end
      ])
    end
  end
end
