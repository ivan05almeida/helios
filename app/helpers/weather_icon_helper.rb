module WeatherIconHelper
  def svg_for_condition_code(condition_code, is_day: true, style: "", class_name: "", **html_options)
    filename = resolve_filename(condition_code, is_day: is_day)
    file_path = Rails.root.join("app", "assets", "images", "weathericons", filename)

    return nil unless File.exist?(file_path)

    svg_content = File.read(file_path)
    doc = Nokogiri::HTML::DocumentFragment.parse(svg_content)
    svg = doc.at_css("svg")

    return nil unless svg

    svg["style"] = [svg["style"], style].compact.reject(&:blank?).join("; ")
    svg["class"] = [svg["class"], class_name].compact.reject(&:blank?).join(" ")
    
    html_options.each { |key, value| svg[key.to_s.dasherize] = value }

    doc.to_html.html_safe
  end

  private

  def resolve_filename(code, is_day:)
    case code.to_i
    when 0
      is_day ? "clear-day.svg" : "clear-night.svg"
    when 1
      is_day ? "mostly-clear-day.svg" : "mostly-clear-night.svg"
    when 2
      is_day ? "partly-cloudy-day.svg" : "partly-cloudy-night.svg"
    when 3
      "cloudy.svg"
    when 45, 48
      "fog.svg"
    when 51..57
      "drizzle.svg"
    when 61..67, 80..82
      "rain.svg"
    when 71..77, 85..86
      "snow.svg"
    when 95..99
      "thunderstorm.svg"
    else
      "unknown.svg"
    end
  end
end