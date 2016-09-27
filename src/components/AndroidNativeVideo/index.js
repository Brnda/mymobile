'use strict';
import { PropTypes } from 'react';
import { requireNativeComponent, View } from 'react-native';

var nativeInterface = {
  name: 'AndroidNativeVideo',
  propTypes: {
    src: PropTypes.string,
    ...View.propTypes
  }
};

export default requireNativeComponent('RCTAndroidNativeVideo', nativeInterface);