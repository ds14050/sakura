/*
	Copyright (C) 2008, kobake

	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

		1. The origin of this software must not be misrepresented;
		   you must not claim that you wrote the original software.
		   If you use this software in a product, an acknowledgment
		   in the product documentation would be appreciated but is
		   not required.

		2. Altered source versions must be plainly marked as such,
		   and must not be misrepresented as being the original software.

		3. This notice may not be removed or altered from any source
		   distribution.
*/
#ifndef SAKURA_CDOCLOCKER_5E410382_D36E_46CE_B212_07F2F346FD3C_H_
#define SAKURA_CDOCLOCKER_5E410382_D36E_46CE_B212_07F2F346FD3C_H_

#include "doc/CDocListener.h"

class CDocLocker : public CDocListenerEx{
public:
	CDocLocker();

	//�N���A
	void Clear() { m_eIsDocWritable = UNTESTED; m_bNoMsg = m_bNeedRecheck = false; }

	//���[�h�O��
	void OnAfterLoad(const SLoadInfo& sLoadInfo);
	
	//�Z�[�u�O��
	void OnBeforeSave(const SSaveInfo& sSaveInfo);
	void OnAfterSave(const SSaveInfo& sSaveInfo);

	//���
	bool IsDocWritable() const;

	//�`�F�b�N
	void CheckWritable() { m_bNeedRecheck = true; };
private:
	void _CheckWritable();

	enum WritableState { UNTESTED,WRITABLE,UNWRITABLE } m_eIsDocWritable;
	bool m_bNoMsg;
	bool m_bNeedRecheck;
};

inline bool CDocLocker::IsDocWritable() const
{
/*
	CDocLocker �� const ���Ƃ͉����B�t�@�C���̑������Ƃ���΂���͕s�肾�B
	CDocLocker ���ۏ؂ł��� const ��������Ƃ���΁A�e�X�g�������鎞�_�ł�
	�������݉\�������̌���񎦂��ꑱ���邱�Ƃł͂Ȃ����BClear ���Ă΂��܂ł́B
	�s�����������̂𖾂炩�ɂ��邱�Ƃ� CDocLocker �� const ����j��Ȃ��ƍl����B
*/
	if (m_eIsDocWritable == UNTESTED || m_bNeedRecheck) {
		const_cast<CDocLocker*>(this)->_CheckWritable();
	}
	return m_eIsDocWritable == WRITABLE;
}

#endif /* SAKURA_CDOCLOCKER_5E410382_D36E_46CE_B212_07F2F346FD3C_H_ */
/*[EOF]*/
