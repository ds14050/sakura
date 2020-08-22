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

	//クリア
	void Clear() { m_eIsDocWritable = UNTESTED; m_bNoMsg = m_bNeedRecheck = false; }

	//ロード前後
	void OnAfterLoad(const SLoadInfo& sLoadInfo);
	
	//セーブ前後
	void OnBeforeSave(const SSaveInfo& sSaveInfo);
	void OnAfterSave(const SSaveInfo& sSaveInfo);

	//状態
	bool IsDocWritable() const;

	//チェック
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
	CDocLocker の const 性とは何か。ファイルの属性だとすればそれは不定だ。
	CDocLocker が保証できる const 性があるとすれば、テストしたある時点での
	書き込み可能性がその後も提示され続けることではないか。Clear が呼ばれるまでは。
	不明だったものを明らかにすることは CDocLocker の const 性を破らないと考える。
*/
	if (m_eIsDocWritable == UNTESTED || m_bNeedRecheck) {
		const_cast<CDocLocker*>(this)->_CheckWritable();
	}
	return m_eIsDocWritable == WRITABLE;
}

#endif /* SAKURA_CDOCLOCKER_5E410382_D36E_46CE_B212_07F2F346FD3C_H_ */
/*[EOF]*/
