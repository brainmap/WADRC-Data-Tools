ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
   :datetime_military     => '%Y-%m-%d %H:%M',
   :datetime              => '%Y-%m-%d %I:%M%P',
   :time                  => '%I:%M%P',
   :time_military         => '%H:%M%P',
   :datetime_short        => '%m/%d %I:%M',
   :ymdhms                => '%Y-%m-%d %H:%M:%S',
   :month_name            => '%B',
   :datetime_daymonthweek => lambda { |time| time.strftime("%A, %B #{time.day.ordinalize}, %Y at %I:%M%p")}
)