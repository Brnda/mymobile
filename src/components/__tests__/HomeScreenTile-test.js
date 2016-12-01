'use strict';

import React from 'react';
import { expect } from 'chai';
import {Text} from 'react-native';
import HomeScreenTile from '../HomeScreenTile';
import { shallow, mount, render } from 'enzyme';
import chaiEnzyme from 'chai-enzyme'
chai.use(chaiEnzyme);

describe('<HomeScreenTile/>', ()=> {
  it('should show status if there\'s a status', () => {
    const props = {
      text: "Title Text"
    };
    const homeScreenTile = shallow(<HomeScreenTile/>);
    console.log(homeScreenTile);
    console.log(homeScreenTile.find(Text));
    console.log(homeScreenTile.find(Text).first());
    console.log(homeScreenTile.find(Text).first().text());

    expect(homeScreenTile
      .find(Text)
    ).to.have.length(1);

  });
});