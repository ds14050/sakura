#include "StdAfx.h"
#include "CDocLocker.h"
#include "CDocFile.h"
#include "window/CEditWnd.h"



// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
//               コンストラクタ・デストラクタ                  //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

CDocLocker::CDocLocker()
: m_eIsDocWritable(UNTESTED)
, m_bNoMsg(false)
, m_bNeedRecheck(false)
{
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
//                        ロード前後                           //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

void CDocLocker::OnAfterLoad(const SLoadInfo& sLoadInfo)
{
	CEditDoc* pcDoc = GetListeningDoc();

	m_bNoMsg = sLoadInfo.bWritableNoMsg;

	// ファイルの排他ロック
	pcDoc->m_cDocFileOperation.DoFileLock();
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
//                        セーブ前後                           //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

void CDocLocker::OnBeforeSave(const SSaveInfo& sSaveInfo)
{
	CEditDoc* pcDoc = GetListeningDoc();

	// ファイルの排他ロック解除
	pcDoc->m_cDocFileOperation.DoFileUnlock();
}

void CDocLocker::OnAfterSave(const SSaveInfo& sSaveInfo)
{
	CEditDoc* pcDoc = GetListeningDoc();

	m_eIsDocWritable = WRITABLE;
	m_bNeedRecheck = false;

	// ファイルの排他ロック
	pcDoc->m_cDocFileOperation.DoFileLock();
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //
//                         チェック                            //
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- //

//! 書き込めるか検査
void CDocLocker::_CheckWritable()
{
	CEditDoc* pcDoc = GetListeningDoc();

	m_bNeedRecheck = false;

	// ファイルが存在しない場合 (「開く」で新しくファイルを作成した扱い) は、以下の処理は行わない
	if( !fexist(pcDoc->m_cDocFile.GetFilePath()) ){
		m_eIsDocWritable = WRITABLE;
		return;
	}

	// 読み取り専用ファイルの場合は、以下の処理は行わない
	if( !pcDoc->m_cDocFile.HasWritablePermission() ){
		m_eIsDocWritable = UNWRITABLE;
		return;
	}

	WritableState IsWritableOld = m_eIsDocWritable;

	// 書き込めるか検査
	CDocFile& cDocFile = pcDoc->m_cDocFile;
	m_eIsDocWritable = cDocFile.IsFileWritable() ? WRITABLE : UNWRITABLE;
	if(m_eIsDocWritable == UNWRITABLE && ! m_bNoMsg && IsWritableOld != UNWRITABLE){
		// 排他されている場合だけメッセージを出す
		// その他の原因（ファイルシステムのセキュリティ設定など）では読み取り専用と同様にメッセージを出さない
		// 編集禁止だったファイルを読み直したときには改めてメッセージを出さない(m_bNoMsg)。
		// 書き込み可能状態が 不可ではない(不明,可能)→不可 と変化した場合にだけメッセージを出す。
		if( ::GetLastError() == ERROR_SHARING_VIOLATION ){
			TopWarningMessage(
				CEditWnd::getInstance()->GetHwnd(),
				LS( STR_ERR_DLGEDITDOC21 ),	//"%ts\nは現在他のプロセスによって書込みが禁止されています。"
				cDocFile.GetFilePathClass().IsValidPath() ? cDocFile.GetFilePath() : LS(STR_NO_TITLE1)	//"(無題)"
			);
		}
	}
}
