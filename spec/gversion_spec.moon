v = require 'gversion'

valid_versions =
  '0.12':            { '0', '12' }
  '0.12a':           { '0', '12', suffix: 'a' }
  '1.005':           { '1', '005' }
  '2.5-r0':          { '2', '5', r: '0' }
  '0-r1':            { '0', r: '1' }
  '20160905':        { '20160905' }
  '2.5_rc':          { '2', '5', rc: '0' }
  '2.5_rc3':         { '2', '5', rc: '3' }
  '2.5_beta_pre2':   { '2', '5', beta: '0', pre: '2' }
  '2.5_beta3_p1':    { '2', '5', beta: '3', p: '1' }
  '2.5c_pre1_p2-r3': { '2', '5', suffix: 'c', pre: '1', p: '2', r: '3' }

invalid_versions = {
  '1_2_3',
  '1.2-3',
  '1.a',
  '1.2a.3b',
  '1.2ab',
  '1.2b3',
  '1.2-rc1',
  'a-r0',
  '1.2_foo6',
  '1.2-r1-r2',
}


describe '.normalize', ->

  for { input        , expected       } in *{
      { 'v1.2.3'     , '1.2.3'        }
      { 'r155'       , '155'          }
      { '7_20_0'     , '7.20.0'       }
      { '2-8-0'      , '2.8.0'        }
      { '1.2-3'      , '1.2.3'        }
      { '4.0.0alpha3', '4.0.0_alpha3' }
      { '7.25BETA2'  , '7.25_beta2'   }
      { '7.2-beta'   , '7.2_beta'     }
      { '0.12pre6'   , '0.12_pre6'    }
      { '1.2rc3'     , '1.2_rc3'      }
      { '1.2rc'      , '1.2_rc'       }
      { '5.9.2p1'    , '5.9.2_p1'     }
      { '0.10.0a1'   , '0.10.0a_p1'   }
      { '4.3.5b1'    , '4.3.5b_p1'    }

      { '1.2build6'   , '1.2build6'   }
  } do
    it "converts #{input} into #{expected}", ->
      assert.same(expected, v.normalize(input))

  for input, _ in pairs valid_versions
    it "does not affect valid version #{input}", ->
      assert.same(input, v.normalize(input))

  for input in *{ nil, 1, true, {1}, -> 1 }
    it "raises error when given argument of type #{type(input)}", ->
      assert.has_error -> v.normalize(input)


describe '.parse', ->

  for input, expected in pairs valid_versions
    it "returns Version table when given valid version: #{input}", ->
      assert.same(expected, v.parse(input))
      assert.same(expected, v(input))

  for input in *invalid_versions
    it "returns nil when given malformed version: #{input}", ->
      assert.is_nil(v.parse(input))
      assert.is_nil(v(input))

  for input in *{ nil, 1, true, {1}, -> 1 }
    it "raises error when given argument of type #{type(input)}", ->
      assert.has_error -> v.normalize(input)


describe '.compare', ->

  for { a              , b         , expected } in *{
      { '0.12'         , '0.12'    ,  0       }
      { '1.5'          , '1.005'   ,  0       }
      { '2.2.0'        , '2.2'     ,  0       }
      { '3.2.1'        , '3.2'     ,  1       }
      { '4.5a'         , '4.5'     ,  1       }
      { '5.5a'         , '5.5.1'   , -1       }
      { '6.5_pre'      , '6.5'     , -1       }
      { '7.2_rc'       , '7.2_rc0' ,  0       }
      { '8.2_rc'       , '8.2_rc1' , -1       }
      { '9.2_rc1'      , '9.2_rc2' , -1       }
      { '10.2'         , '2.2'     ,  1       }
      { '11.5_beta_pre', '11.5_pre', -1       }
      { '12.2_p1'      , '12.2'    ,  1       }
      { '13-r0'        , '13'      ,  0       }
      { '14-r1'        , '14'      ,  1       }
      { '15-r12'       , '15-r3'   ,  1       }
      { '16_p1-r1'     , '16-r3'   ,  1       }
  } do
    it "#{a}, #{b} -> #{expected}", ->
      a, b = v.parse(a), v.parse(b)
      assert.same(expected, v.compare(a, b))
      switch expected
        when 1  then assert.is_true a > b
        when 0  then assert.is_true a == b
        when -1 then assert.is_true a < b


describe 'Version:__tostring', ->

  for expected, _ in pairs valid_versions
    it "returns same string as parsed: #{input}", ->
      ver = v(expected)
      assert.same(expected, tostring(ver))


describe 'aliases', ->

  for alias, index in pairs { major: 1, minor: 2, tiny: 3 }
    it "ver.#{alias} is alias for ver.#{index}", ->
      ver = v.parse('3.2.1')
      assert.same(ver[index], ver[alias])

    it "ver.#{alias}= is alias for ver.#{index}=", ->
      ver = v.parse('3.2.1')
      ver[alias] = '42'
      assert.same('42', ver[index])
