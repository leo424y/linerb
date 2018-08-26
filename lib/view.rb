def render_html
  yy = to_model params['yy']
  @datas = yy.last(100).reverse

  erb <<-EOF
  <!DOCTYPE html>
  <html>
    <head>
      <title>LinerbSite</title>
    </head>
    <body>
      <table>
        <tbody>
          <% @datas.each do |d| %>
            <tr>
              <% values = d.attributes.values %>
              <% values.each do |v| %>
                <td><%= v if (v.to_s.length < 20) %></td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </body>
  </html>
  EOF
end

def display_info
  request_j = if params['yy'].start_with? 'U'
    JSON.parse(client.get_profile(params['yy']).read_body)['displayName']
  elsif params['yy'].start_with? 'C'
    JSON.parse(client.get_group_member_ids(params['yy']).read_body)
  end
  erb <<-EOF
  <!DOCTYPE html>
  <html>
    <body>
      <%= #{request_j} %>
    </body>
  </html>
  EOF
end

def download_csv
  content_type 'application/octet-stream'
  CSV.generate do |csv|
    yy = to_model params['yy']
    csv << yy.attribute_names
    yy.all.each do |user|
      csv << user.attributes.values
    end
  end
end
