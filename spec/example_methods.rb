# frozen_string_literal: true

module ExampleMethods
  def expect_log_message(logger, level, message_regex, progname = "LogstashWriter")
    expect(logger).to receive(level.to_sym) do |pn, &msg|
      expect(pn).to eq(progname)
      expect(msg.call).to match(message_regex)
    end
  end
end
