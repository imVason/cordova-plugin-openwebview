# cordova-plugin-openwebview

该插件给 Cordova App 提供打开多个 webview 的能力，也可以在一个已经打开的 webview 内部调用方法，打开一个子 webview，Demo 如下。



[English](./README.md) | 中文介绍



## 截图

<img src="res/demo.gif" alt="demo" style="width:360px" />



## 支持平台

- Android
- iOS



## 安装



```
cordova plugin add cordova-plugin-openwebview
```



## 方法

- cordova.plugins.openWebview.open



## cordova.plugins.openWebview.open

```javascript
cordova.plugins.openWebview.open(openOptions, openSuccess, openError);
```



### open参数

- openOptions
- openSuccess
- openError



#### openOptions

| openOptions参数   | Required | Data Typ | Default Value | Description                                                  |
| ----------------- | -------- | -------- | ------------- | ------------------------------------------------------------ |
| ***url***         | true     | String   | *null*        | 要使用插件打开的URL，**不能为空**                            |
| ***inSubView***   | false    | Boolean  | *false*       | 默认以全屏打开webview，如果值为 **true** 则效果如同截图所示。 |
| ***showBackBtn*** | false    | Boolean  | *false*       | 默认隐藏返回按钮，true 为显示.                               |



### 示例

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



## 打开子 webview

你可以使用以下方法在已经通过 `cordova.plugins.openWebview.open` 打开的子webview页面中打开新的webview，都需要传入一个参数，参数内容与 `openOptions` 一样。

- window.webkit.messageHandlers.openNew.postMessage (iOS)
- openWebview.openNew (Android)



### window.webkit.messageHandlers.openNew.postMessage

#### 示例

```javascript
var openOptions = {
    url: "https://www.google.com",
    inSubView: false,
    showBackBtn: false
};

window.webkit.messageHandlers.openNew.postMessage(openOptions);
```



### openWebview.openNew

#### 示例

```javascript
var openOptions = {
    url: "https://www.google.com",
    inSubView: false,
    showBackBtn: false
};

openWebview.openNew(JSON.stringify(openOptions));
```



## 使用系统浏览器打开网页

如果想要调用系统浏览器打开网页，只需要在 url 的后面加上 `#webview-external`。

### 示例

```javascript
var openOptions = {
    url: "https://www.google.com#webview-external"
};

cordova.plugins.openWebview.open(openOptions);

// 以及

window.webkit.messageHandlers.openNew.postMessage(openOptions);

// 以及

openWebview.openNew(JSON.stringify(openOptions));
```



## 待完成

- [ ]  自定义操作栏背景色
- [ ]  自定义可打开的webview数量（当前只可打开两个webview）
- [ ]  从子webview发送自定义消息



## 感谢

- [CustomIOSAlertView](https://github.com/wimagguc/ios-custom-alertview) 



## License

[MIT](https://opensource.org/licenses/MIT)

Copyright (c) 2020, Vason