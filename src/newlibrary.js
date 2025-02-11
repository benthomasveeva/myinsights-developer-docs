const isWin8 = navigator.platform.toLowerCase().indexOf("win") >= 0;
const isIPad = Boolean(
  window.webkit &&
    window.webkit.messageHandlers &&
    window.webkit.messageHandlers.myInsightsAPI,
);
const isWindowsMobile =
  typeof window.external !== "undefined" && "notify" in window.external;
const isOnline = !isIPad && !isWindowsMobile;

/**
 * When receiving an event response from the parent iframe - try to parse the data results.
 * Multiple platforms handle this differently, thus the various checks of the data format.
 * @param event the raw response from the parent iframe message
 * @returns response data from parent iframe message
 */
const parseEventResponse = (event) => {
  if (typeof event === "object") {
    if (typeof event.data === "string") {
      return JSON.parse(event.data);
    } else {
      return event.data;
    }
  } else if (typeof event === "string") {
    try {
      return JSON.parse(event).data;
    } catch (error) {
      console.error("Fail to parse response: " + error);
    }
  }

  return {};
};

/**
 * Gets the height of the X-Page content in the iframe.
 * @returns {{height: number}}
 */
const getIFrameDimensions = () => {
  return {
    height: document.scrollingElement.offsetHeight,
  };
};

/**
 * Send the iframe content height to the parent context so it can adjust iframe height dynamically with the content.
 */
const sendIFrameDimensionsToParentWindow = () => {
  const iframeDimensionsToRequest = getIFrameDimensions();
  if (iframeDimensionsToRequest.height !== 0) {
    doPostMessage({
      command: "iframeDimensions",
      iframeDimensions: iframeDimensionsToRequest,
    });
  }
};

/**
 * Resolves or rejects the Promise based on the response data returned from the parent iframe message.
 * @param data The data object returned from the parent iframe
 */
const resolveOrRejectResponse = (data) => {
  const messageRegistry = window.xpages._MESSAGE_REGISTRY;
  const promise = messageRegistry[data.messageId];
  if (promise) {
    if (data.command === "error") {
      promise.reject(data);
    } else {
      if (!!data.success) {
        promise.resolve(data);
      } else {
        promise.reject(data);
      }
    }
    delete messageRegistry[data.messageId];
  } else {
    console.warn("Promise not found in registry");
  }
};

/**
 * Attaches the message listener to the window to listen to messages coming from the parent iframe.
 * Also attaches a listener to resize events to inform the parent iframe of content size changes such
 * that it can resize the parent iframe to always fit the content.
 */
const attachEventListeners = () => {
  window.addEventListener("message", function (event) {
    if (event) {
      resolveOrRejectResponse(parseEventResponse(event));
    }
  });

  window.addEventListener("load", function () {
    // Creates a ResizeObserver that listens to when the body size changes and sends the new iframe dimensions to the parent
    ds.resizeObserver = new ResizeObserver(function () {
      sendIFrameDimensionsToParentWindow();
    });

    // document.body is only defined once the window has loaded
    ds.resizeObserver.observe(document.body);
  });
};

/**
 * Initializes the global namespace with the message registry to connect the Promise returned from public
 * library functions to the message event from the parent iframe that resolves or rejects that Promise.
 * The message counter ensures that all messages passed between iframe is uniquely identifiable with the calling context.
 */
const init = () => {
  if (!window.xpages) {
    const xPagesGlobal = {
      _MESSAGE_REGISTRY: {},
      _MESSAGE_COUNTER: 0,
    };
    window.xpages = xPagesGlobal;
    attachEventListeners();
  }
};

/**
 * Utility method to send a message to the iframe's parent context.  This method takes into consideration which platform
 * this library is being called within and sends the message appropriately.
 * @param messageBody The message to be passed to the iframe's parent context.
 * @returns {Promise} Promise that will be resolved or rejected with the response to the message.
 */
const doPostMessage = (messageBody) => {
  return new Promise((resolve, reject) => {
    const messageId = window.xpages._MESSAGE_COUNTER;
    window.xpages._MESSAGE_COUNTER += 1;

    window.xpages._MESSAGE_REGISTRY[messageId] = {
      resolve,
      reject,
    };
    if (messageBody && typeof messageBody === "object") {
      messageBody.messageId = messageId;
    } else {
      messageBody = { messageId };
    }

    if (isWin8 && isWindowsMobile) {
      window.external.notify(JSON.stringify(messageBody));
    } else if (isOnline) {
      window.parent.postMessage(JSON.stringify(messageBody), "*");
    } else {
      window.webkit.messageHandlers.myInsightsAPI.postMessage(
        JSON.stringify(messageBody),
      );
    }
  });
};

export const getDataForCurrentObject = (object, field) => {
  return doPostMessage({
    command: "getDataForObjectV2",
    object,
    fields: [field],
  });
};

export const getObjectLabels = (objects) => {
  return doPostMessage({
    command: "getObjectLabels",
    object: objects,
  });
};

export const ds = {
  getDataForCurrentObject,
  getObjectLabels,
};

// init is called explicitly to ensure that the required global namespace is correctly setup
init();
