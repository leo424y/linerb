def number_to_cost_h user_id, place_info, cost
  {
    type: 'template',
    altText: 'Confirm alt text',
    template: {
      type: 'confirm',
      text: "確認在#{place_info[1]}花了#{cost}元？",
      actions: [
        { label: '是的', type: 'postback', data: "book/#{user_id}/#{place_info[0]}/#{place_info[1]}/#{cost}"},
        { label: '沒有', type: 'postback', data: '好的，沒有' },
      ],
    }
  }
end
