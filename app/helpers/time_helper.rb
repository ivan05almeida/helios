module TimeHelper
  def display_time(time, timezone)
    return "—" unless time

    time.in_time_zone(timezone).strftime("%H:%M")
  end
end
