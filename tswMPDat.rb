#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# asm codes: tswMPExt_*.asm

module MPExt
  MP_PATCH_BYTES_1 = [[0x489DE4, 28, "            SetDCBrushColor "],
[0x4BA1DC, 3064, "BeginPath   EndPath StrokePath                �         Tahoma  \x22�\x22 ��\x60 �\x22\x22 @� ��� fff ��� �؋u1�8��K tT���K �@4;�H t;�H u<��h  � RR�1�5��K �R������W8������P�F�p�p�u�W�5��K 轩���1�8��K tA���K �v4;5�H t;5�H u)��Rj�RRR�uW�5��K �uP�1�5��K �����I���I���=��K  u���f�UWVSP��T  �p,�=�H  t�D$�  �  �D$�7����������K �~ tx��=̆K t�u�  ���  �t�=��H  ��&��t�=��H  ��  �&��z  �\r��H �A���   �)� ���K 1�k$h  � SSPRRSSW�4���K P����萨���5̡K W�5ġK WjW�����������ީ��������@���$$�����$$�ȋӀʀ���z  C��yu�UWVW諩��覩����   �=��H  �$h\x60�K �ȡ��K k�@�������K  ���ȋڋ��,  ��H ��H ;D$D��a6�������躀�H ��\x1a<ys29�t.�Ǳ��@���$$�����$$���Ȉ�����  �Έ�� ����  ���H ��\x1a<ys_)Ë��K Ku��uCCu��\nu\n��t���u=k��K {��6�K u,�ر��@���$$�����$$���ȋӋ��n  �΋Ӌ��c  ^k�X���h  � j j WVV�5|�H �5x�H P����[^_]� WVS��   ������P�������K ��1��54�K PjPT�����ġK �0�K �D$T�	����ȡK ��h��K �����̡K h^�K ��l��h�H Ph�K Ph�K PhܡK P諥���СK 补���ԡK 藥���ءK 荥����H j�A����ܦH 1�Ch�  h�  V�a�������K PW裧�����H �4�����1ҹ�  h  � RRPQQRRW�	���Kt��\r��K ���K [^_����K  hŦK S1�C���H �T4���������K ��  h  � j j RQQj j P�4���K R�\x1a���襥��Kt�[À=��K  t1V���K j j �6覥��P�6������P�֥���P�ߥ����̡K v�^Ð1�f=��u\n�??? �A�f=\n rAf=d rAf=�rAf='rAQS��\n1�f���0�Kf��u�[X@� ��<r-<=s<s%���<as,=��ò<jrB<zt�P���,�<\x1a��CЈ��f�UWVS���T$�-�K E���K �������H �~���H��r<u�=؆K ����=�K ��<��!Ȉ$��)�������1���@��  9�G̀f����   �<$ tً��D$��~H1���N����1�+\r��K HȋD$��ȸ�  ��tG��t\x1a�D$H1�����<$ t��)�1���@��  9�B�;\r��K r�π�A�1���@���  9�Bȋ���f�ȃ�[^_]�U����,� �H ���t�WVS�� ��������U�d$���$��xj\rS�58�K �	jS�5(�K S�,��������<$ u(jS������5ġK S�դ���D$�5̡K S�Ť���D$S�СK �ōT$������T$��f�|$ tr��FURWVS�����f�D$f=�t�T$�����D$�T$�O�PRQVS�Ҥ��S�ԡK S�ءK �T$URWVS趤��f�|$�t[���T$�t$RWVS虤���E��H ��T  �@,�L$�1�y)ǉyƉqj%QURSSSj%QURS�;����ԡK �ءK �*����<$ u�t$S�ڣ���t$S�У����$[^_]�VSP1�k��K {��6�K �3�&������   ��t	�=,�K  t#������� �H 9t	��\r��K C��yu�X[^�1҉$�ò��Ȅ�t�D3�������$��\nt\r�D3������D$��t\r�D3������D$��\nt\r�D3�����D$�$1Ɋ��u���   ��u��d@�T$9�u��K �P�ʡ��K f�<$t	f�|$u	��~@����$���3���1ҍA��4$@;\r��K �������  9�B�	�����1ҋ\r��K �� u<���?������2u9�K t�9�K u�<���݃�(u�~GtҀ~t̃�M���ă�1u�~<t���,s�9��H ~�������u��~Rt�<t��f���H ��T  �R,�P�P��\r �H )щ�\r�H )щH� ��.���r������-��H �T-��H ���u��u$�x�H �J�� �H �F��?��))N��9�s�h  � QQW�����r���YZ�L$�T$h�  j ���K �P�t�P�w��������D$�Y  �������K ��H ��   ����� S��QPh� � ����H ���4� �K S��H ��������5ܦH S�����D$S�Ơ��������[f���H ��?t/��BQPRh �H P�5ȡK PjP������Р���D$藠��� ��ÐUWVS��T  �q,��   �,�����1�C���H �-���������T��H t7����h  � h�  j �5��K �����;���W���K �t��1�R����ݞ��8��H uk�h  � j j WVV�|�H �1�q�U趞��Kt����K  ��H  [^_]À{� x�u	�=̆K u��j���f� "]
  ]
# in order to save space for opcodes storage as well as make the string still able to be parsed by Ruby and n++: {str}.each_byte {|i| if i == 0x22 then print '\x22' elsif i == 0x60 then print '\x60' elsif i == 0x1a then print '\x1a' elsif i == 0x5c then print "\\\\" elsif i == 0xd then print '\r' elsif i == 0xa then print '\n' else print i.chr end}
  MP_PATCH_BYTES_2 = [[0x46396F, 5, "�Hm "],
[0x4638E4, 5, "��m "],
[0x484B50, 5, "�g[ "],
[0x44314E, 4, "�q "],
[0x443276, 4, "vp "],
[0x417EA8, 4, "�#\n "],
[0x41A5C6, 5, "�q�	 "],

[0x442C4A, 58, "@�����\r��K �7�Ɗ��H ���T  �J,����P�H P����L�H �"],
[0x450BE7, 9, "�\r��K f� "],
# for the string to be able to be parsed by n++ for Ruby syntax highlight: if the last byte is >=0x80, add a space at the end (otherwise n++ might think the last byte plus the quote sign make a 2-byte wide char, thus not recognizing the closing quote)
[0x451939, 20, "�EN�H     �\r��K f� "],
[0x44A54A, 25, "�T�H �-�   �B�Bd�\r��K "],
[0x449E66, 13, "1ۉJ�\r��K � "],

[0x442F1D, 44, "ha/D h�K ��=��K  t�=��K  xu�=̆K t��� "],
[0x45458F, 164, "hFE �p�H ���H P���K kV9�u��������L�H �B0B�J,\n��T  �R,�fRfQP�D$kV�{��6�K HP��   ���  �L8����   �Mc��YZ�����}b ����H k�|���  �|���  �	�� "],
[0x454741, 7, "�N����l"],

[0x48074B, 49, "��H E�H �|���P�5�H �L�H �\rP�H �D���X�f   �"],
[0x4807C5, 111, "�X�H �T�H ���  �L   �C'���f�����T  �R,�\r\\�H �5h�H ��u(��ـ���v��� P�H ��f�L�H �k�T2�Y� � "],
[0x480A29, 95, "��H ����P�5�H �L�H �\rP�H �m���X����f�k�|2�t2� �H ����������k��K {6�K �8�8�0"]
  ]
  MP_PATCH_BYTES_3 = [[0x443eda, 98, "1��șh(?D PkGG �kW{��6�K ���H HPQ�~8 t�\r �F8D$�辛�����  �Y�?��Ë�T  �@,1ɲ�����	"],
[0x443cfe, 31, "1���T  �I,����  1��Ȳ���  �K"],
[0x443b2a, 31, "1��ȋ��  1���T  �I,��  �K"],
[0x4441DF, 31, "��T  �@,1ɋ������1��Ȳ�������L"],
[0x443767, 18, "���K 1��ȋ��m  �'"],

[0x480834, 496, "S�؋�T  �H,��H �����С��H �������P�����k��K {��H ��6�K ���H HPQ�t$P���  �u���C����H �=�����Y�T�H $���  �u����S��1҉��H h�H ��2D �_1D �=��H  t�SVQSV������H �4��H ��   �x�H �\r|�H �� [ÐS��������H �P�5��H E��0��   �x�H �\r|�H 赙 �5��H 뜹��K �L�H �2���A�B�A�B��K �Bf�fX���a�A��K Ð���K �L�H ��q���Q�5�K ���H  ����P�\x22���$������$�v����$�[��X�@���S�ع�H Q�HGE �P������Yt;�!�t/�z�r�-5  ��GE �u����ʊ�J��:��\ns�<-t<+u�����GE [� "]
  ]
end

EXT_BMP = ["(   (   (         \x22                ��� f�f  �  fff ��� ", "DDDDDDDDDDDDDDDDDDDDDDDDDDC33DDDDDDDDDDDDDDDDD333DDDDDDDDDDDDDDDDC#334DDC3DDDDDDDDDDDA!\x22\x224DD334DDDDDDDDDDDQ333333DDDDDDDDDDD%UQ\x22332234DDDDDDDDDD\x22UUQ\x22\x22\x22DDDDDDDD33!UUUUUUUUDDDDDDDC33!UUUUUUUUTDDDDDDDA\x22!UUUUUUUDDDDDDDDAUUUUDDUUUTDDDDDDDDEUUUUDDDEUUDDDDDDDDDUUQDDDAUQDDDDDDDDDAUDDDDUU\x2234DDDDDDDDAU$DDDQ33DDDDDDDDAU3DDB!UU\x22\x22$DDDDDDDAUR3333!UUUQDDDDDDDEUU332UUUUDDDDDDDAUUUQ\x22UUUUUDDDDDDDDDUUUUUUU!QDDDDDDDDDAURUUUTDDDDDDDDDDDDDDDAUUUQDDDDDDDDDDDDDDDDUUQDDDDDDDDDDDDDDDDAUUDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"]
