module ApplicationHelper
  def status_badge(status)
    colors = {
      "pending"  => "bg-yellow-100 text-yellow-800",
      "reviewed" => "bg-blue-100 text-blue-800",
      "rejected" => "bg-red-100 text-red-800",
      "accepted" => "bg-green-100 text-green-800"
    }
    css = colors.fetch(status.to_s, "bg-gray-100 text-gray-800")
    content_tag(:span, status.to_s.capitalize, class: "px-2 py-1 rounded text-xs font-semibold #{css}")
  end
end
