import React, {Component} from 'react';
import styles from './styles';
import {
    StyleSheet,
    View,
    Text,
    StatusBar,
    TouchableOpacity,
    Image
} from 'react-native';
import * as Progress from 'react-native-progress';
import {connect} from 'react-redux';

class HomeScreenTile extends Component {
  constructor(){
    super();
    this.state = {fechedCameras: true}
  }

  _onSelect() {
    console.log(`camerazz ${this.props.uri}`)
    this.props.onSelect(this.props.spaceId, this.props.uri);
  }

  _selectStatusText(percentage) {
    if(percentage >= 0 && percentage <= 0.25) {
      return {text: 'ALMOST EMPTY', color: '#39a851'};
    }

    if(percentage > 0.25 && percentage <= 0.50) {
      return {text: 'SOMEWHAT EMPTY', color: '#8cce1f'};
    }

    if(percentage > 0.50 && percentage <= 0.75) {
      return {text: 'GETTING FULL', color: '#edba00'};
    }

    if(percentage > 0.75 && percentage <= 1) {
      return {text: 'FULL', color: '#df0a0a'};
    }

    return {text: 'NO DATA', color: 'black'};
  }

  componentWillMount() {
    // if(this.props.spaces[this.props.spaceId]) {
    //   console.log(`in here ${this.props.spaces[this.props.spaceId]}` )
    //   if(this.props.spaces[this.props.spaceId].camera_ids) {
    //     console.log(`Calling mother ship`)
    //     this.props.getCamera(this.props.spaces[this.props.spaceId].camera_ids[0]);
    //   }
    // }
  }

  componentWillReceiveProps(nextProps) {
    if(this.state.fechedCameras && nextProps.spaces[nextProps.spaceId] && nextProps.spaces[nextProps.spaceId].camera_ids) {
      this.props.getCamera(nextProps.spaces[nextProps.spaceId].camera_ids[0]);
      this.setState({fechedCameras: false});
      console.log(`getting cameras! ${JSON.stringify(nextProps.spaces[nextProps.spaceId].camera_ids[0])}`);
    }
  }

  render() {
    const percentage = this.props.statusBarFilled / this.props.statusBarTotal;
    return (
      <TouchableOpacity style={styles.container} onPress={this._onSelect.bind(this)}>
        <Image source={this.props.icon} style={styles.icon}/>
        <Text>{this.props.text}</Text>
        {(this.props.statusBarTotal && this.props.statusBarTotal > 0) &&
          <View style={{alignItems: 'center'}}>
            <Progress.Bar
              style={styles.progressBar}
              progress={percentage}
              width={120}
              indeterminate={this.props.fetching}
              color={this._selectStatusText(percentage)['color']}/>

            <Text style={styles.statusText}>{this._selectStatusText(percentage).text}</Text>
          </View>
        }
      </TouchableOpacity>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  console.log(`called camera updates! ${JSON.stringify(state.camera.get('CAMERA'))}`)
  console.log(`called spaces updates! ${JSON.stringify(state.spaces.get('SPACES'))}`)
  // const sst = state.spaces.get('SPACES');
  //  if(sst.pool && sst.pool.camera_ids) {
  //   this.setState({fechedCameras: true})
  //  }
  return {
    spaces: state.spaces.get('SPACES'),
    camera: state.camera.get('CAMERA')
  }
};


export default connect(mapStateToProps, null)(HomeScreenTile);
