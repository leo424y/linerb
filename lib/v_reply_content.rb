def reply_buttons
  reply_content(event, {
    type: 'template',
    altText: 'Buttons alt text',
    template: {
      type: 'buttons',
      thumbnailImageUrl: THUMBNAIL_URL,
      title: 'My button sample',
      text: 'Hello, my button',
      actions: [
        { label: 'Go to line.me', type: 'uri', uri: 'https://line.me' },
        { label: 'Send postback', type: 'postback', data: 'hello world' },
        { label: 'Send postback2', type: 'postback', data: 'hello world', text: 'hello world' },
        { label: 'Send message', type: 'message', text: 'This is message' }
      ]
    }
  })
end

def reply_confirm
  reply_content(event, {
    type: 'template',
    altText: 'Confirm alt text',
    template: {
      type: 'confirm',
      text: 'Do it?',
      actions: [
        { label: 'Yes', type: 'message', text: 'Yes!' },
        { label: 'No', type: 'message', text: 'No!' },
      ],
    }
  })
end

def reply_carousel
  reply_content(event, {
    type: 'template',
    altText: 'Carousel alt text',
    template: {
      type: 'carousel',
      columns: [
        {
          title: 'hoge',
          text: 'fuga',
          actions: [
            { label: 'Go to line.me', type: 'uri', uri: 'https://line.me' },
            { label: 'Send postback', type: 'postback', data: 'hello world' },
            { label: 'Send message', type: 'message', text: 'This is message' }
          ]
        },
        {
          title: 'Datetime Picker',
          text: 'Please select a date, time or datetime',
          actions: [
            {
              type: 'datetimepicker',
              label: "Datetime",
              data: 'action=sel',
              mode: 'datetime',
              initial: '2017-06-18T06:15',
              max: '2100-12-31T23:59',
              min: '1900-01-01T00:00'
            },
            {
              type: 'datetimepicker',
              label: "Date",
              data: 'action=sel&only=date',
              mode: 'date',
              initial: '2017-06-18',
              max: '2100-12-31',
              min: '1900-01-01'
            },
            {
              type: 'datetimepicker',
              label: "Time",
              data: 'action=sel&only=time',
              mode: 'time',
              initial: '12:15',
              max: '23:00',
              min: '10:00'
            }
          ]
        }
      ]
    }
  })
end

def reply_image_carousel
  reply_content(event, {
    type: 'template',
    altText: 'Image carousel alt text',
    template: {
      type: 'image_carousel',
      columns: [
        {
          imageUrl: THUMBNAIL_URL,
          action: { label: 'line.me', type: 'uri', uri: 'https://line.me' }
        },
        {
          imageUrl: THUMBNAIL_URL,
          action: { label: 'postback', type: 'postback', data: 'hello world' }
        },
        {
          imageUrl: THUMBNAIL_URL,
          action: { label: 'message', type: 'message', text: 'This is message' }
        },
        {
          imageUrl: THUMBNAIL_URL,
          action: {
            type: 'datetimepicker',
            label: "Datetime",
            data: 'action=sel',
            mode: 'datetime',
            initial: '2017-06-18T06:15',
            max: '2100-12-31T23:59',
            min: '1900-01-01T00:00'
          }
        }
      ]
    }
  })
end

def reply_imagemap
  reply_content(event, {
    type: 'imagemap',
    baseUrl: THUMBNAIL_URL,
    altText: 'Imagemap alt text',
    baseSize: { width: 1024, height: 1024 },
    actions: [
      { area: { x: 0, y: 0, width: 512, height: 512 }, type: 'uri', linkUri: 'https://store.line.me/family/manga/en' },
      { area: { x: 512, y: 0, width: 512, height: 512 }, type: 'uri', linkUri: 'https://store.line.me/family/music/en' },
      { area: { x: 0, y: 512, width: 512, height: 512 }, type: 'uri', linkUri: 'https://store.line.me/family/play/en' },
      { area: { x: 512, y: 512, width: 512, height: 512 }, type: 'message', text: 'Fortune!' },
    ]
  })
end

def reply_flex
  reply_content(event, {
    type: "flex",
    altText: "this is a flex message",
    contents: {
      type: "bubble",
      header: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: "Header text"
          }
        ]
      },
      hero: {
        type: "image",
        url: HORIZONTAL_THUMBNAIL_URL,
        size: "full",
        aspectRatio: "4:3"
      },
      body: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: "Body text",
          }
        ]
      },
      footer: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: "Footer text",
            align: "center",
            color: "#888888"
          }
        ]
      }
    }
  })
end

def reply_flex_carousel
  reply_content(event, {
    type: "flex",
    altText: "this is a flex carousel",
    contents: {
      type: "carousel",
      contents: [
        {
          type: "bubble",
          body: {
            type: "box",
            layout: "horizontal",
            contents: [
              {
                type: "text",
                text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                wrap: true
              }
            ]
          },
          footer: {
            type: "box",
            layout: "horizontal",
            contents: [
              {
                type: "button",
                style: "primary",
                action: {
                  type: "uri",
                  label: "Go",
                  uri: "https://example.com"
                }
              }
            ]
          }
        },
        {
          type: "bubble",
          body: {
            type: "box",
            layout: "horizontal",
            contents: [
              {
                type: "text",
                text: "Hello, World!",
                wrap: true
              }
            ]
          },
          footer: {
            type: "box",
            layout: "horizontal",
            contents: [
              {
                type: "button",
                style: "primary",
                action: {
                  type: "uri",
                  label: "Go",
                  uri: "https://example.com"
                }
              }
            ]
          }
        }
      ]
    }
  })
end

def reply_quickreply
  reply_content(event, {
    type: 'text',
    text: '[QUICK REPLY]',
    quickReply: {
      items: [
        {
          type: "action",
          imageUrl: QUICK_REPLY_ICON_URL,
          action: {
            type: "message",
            label: "Sushi",
            text: "Sushi"
          }
        },
        {
          type: "action",
          action: {
            type: "location",
            label: "Send location"
          }
        },
        {
          type: "action",
          imageUrl: QUICK_REPLY_ICON_URL,
          action: {
            type: "camera",
            label: "Open camera",
          }
        },
        {
          type: "action",
          imageUrl: QUICK_REPLY_ICON_URL,
          action: {
            type: "cameraRoll",
            label: "Open cameraRoll",
          }
        },
        {
          type: "action",
          action: {
            type: "postback",
            label: "buy",
            data: "action=buy&itemid=111",
            text: "buy",
          }
        },
        {
          type: "action",
          action: {
            type: "message",
            label: "Yes",
            text: "Yes"
          }
        },
        {
          type: "action",
          action: {
            type: "datetimepicker",
            label: "Select date",
            data: "storeId=12345",
            mode: "datetime",
            initial: "2017-12-25t00:00",
            max: "2018-01-24t23:59",
            min: "2017-12-25t00:00"
          }
        },
      ],
    },
  })
end
