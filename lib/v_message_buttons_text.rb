def if_message_buttons_text name, opening_hours, offer_info
  if (is_cyc? name)
    "#{opening_hours}\n#{count_exercise name}"
  elsif is_tndcsc? name
    "#{opening_hours}\n#{count_exercise '北運'}"
  elsif is_tpsc? name
    "#{opening_hours}\n#{p_tp_count name}"
  else
    # {"message":"must not be longer than 60 characters","property":"template/text"}
    "#{opening_hours}#{offer_info}"
  end
end
