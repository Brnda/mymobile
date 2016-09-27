import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';

class ViewVideo extends Component {
  render() {
    return (
      <View style={styles.container}>
        <Text>Video!</Text>
        <Text>{JSON.stringify(this.props, null, 2)}</Text>
      </View>
    )
  }
}


ViewVideo.propTypes = {
  spaceId: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  return {
    spaceId: state.spaces.get('SPACE_ID')
  }
}

export default connect(mapStateToProps)(ViewVideo);