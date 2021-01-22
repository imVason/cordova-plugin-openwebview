# cordova-plugin-openwebview

This plugin provide capability of open multiple webview, and you can open a new webview in sub webview page.



 English | [中文介绍](./README_zh.md)

## Screenshot

<img src="res/demo.gif" alt="demo" style="width:360px" />



## Supported Platforms

- Android
- iOS



## Installation



```
cordova plugin add cordova-plugin-openwebview
```



## Methods

- cordova.plugins.openWebview.open



## cordova.plugins.openWebview.open

```javascript
cordova.plugins.openWebview.open(openOptions, openSuccess, openError);
```



### Parameters

- openOptions 
- openSuccess
- openError 



#### openOptions

| Options           | Required | Data Type | Default Value | Description                                                  |
| ----------------- | -------- | --------- | ------------- | ------------------------------------------------------------ |
| ***url***         | true     | String    | *null*        | Target url open in webview, **not null**.                    |
| ***inSubView***   | false    | Boolean   | *false*       | Default open webview with full screen, if value is **true**, the effect will like demo. |
| ***showBackBtn*** | false    | Boolean   | *false*       | Default hide back button, if value is true, will show it.    |



### Example

```javascript
var openOptions = {
    url: "https://www.google.com",
    inSubView: false,
    showBackBtn: false
};

function openSuccess(data) {
    console.log(data);
}

function openError(error) {
    console.log(error);
}

cordova.plugins.openWebview.open(openOptions, openSuccess, openError);
```



## Open sub webview



You can use below methods open a new webview in a sub webview page which has been opened with `cordova.plugins.openWebview.open`, the method only have one option and same as openOptions.

- window.webkit.messageHandlers.openNew.postMessage (iOS)
- openWebview.openNew (Android)



### window.webkit.messageHandlers.openNew.postMessage

#### Example

```javascript
var openOptions = {
    url: "https://www.google.com",
    inSubView: false,
    showBackBtn: false
};

window.webkit.messageHandlers.openNew.postMessage(openOptions);
```



### openWebview.openNew

#### Example

```javascript
var openOptions = {
    url: "https://www.google.com",
    inSubView: false,
    showBackBtn: false
};

openWebview.openNew(JSON.stringify(openOptions));
```



## Open url with system browser

If you want to open url with system browser, only need add  `#webview-external` to the end of url.

### Example

```javascript
var openOptions = {
    url: "https://www.google.com#webview-external"
};

cordova.plugins.openWebview.open(openOptions);

// or

window.webkit.messageHandlers.openNew.postMessage(openOptions);

// or

openWebview.openNew(JSON.stringify(openOptions));
```



## TODO

- [ ]  Custom action bar background color
- [ ]  Custom open webview sum（currently only two webviews can be opened）
- [ ]  Post custom message form sub webview



## Thanks

- [CustomIOSAlertView](https://github.com/wimagguc/ios-custom-alertview) 



## License

[MIT](https://opensource.org/licenses/MIT)

Copyright (c) 2020, Vason